import { Err, None, Ok, Option, Result, Some } from 'ts-results';
import { asOption, asResult } from './utils';

type RenderingContext = WebGL2RenderingContext;

class Renderer {
  gl: RenderingContext;
  isRendering: boolean;
  programSpec: Option<ProgramSpec>;
  fpsCounter: FpsCounter;

  constructor(gl: RenderingContext) {
    this.gl = gl;
    this.isRendering = false;
    this.programSpec = None;
    this.fpsCounter = new FpsCounter();
    initVertexData(gl);
  }

  public run(src: string): void {
    this.stop();
    const programSpec = loadProgram(this.gl, src)
      .mapErr((err) => {
        throw err; // Note: Calling .unwrap() directly doesn't throw the original error.
      })
      .unwrap();
    this.programSpec = Some(programSpec);
    this.isRendering = true;
    this.fpsCounter = new FpsCounter();
    requestAnimationFrame((t) => this.renderLoop(t));
  }

  public stop(): void {
    this.isRendering = false;
  }

  public fps(): number {
    return this.fpsCounter.fps;
  }

  private renderLoop(time: number): void {
    if (!this.isRendering) {
      return;
    }
    this.renderFrame(time / 1000.0);
    this.fpsCounter.update();
    requestAnimationFrame((t) => this.renderLoop(t));
  }

  private renderFrame(time: number): void {
    const gl = this.gl;
    this.programSpec.map((programSpec) => {
      programSpec.resolutionUniformLocation.map((resolutionUniformLocation) => {
        gl.uniform2f(resolutionUniformLocation, gl.canvas.width, gl.canvas.height);
      });
      programSpec.timeUniformLocation.map((timeUniformLocation) => {
        gl.uniform1f(timeUniformLocation, time);
      });

      gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
      gl.drawArrays(gl.TRIANGLES, 0, 6);
    });
  }
}

class ProgramSpec {
  constructor(
    readonly program: WebGLProgram,
    readonly positionAttributeLocation: GLint,
    readonly resolutionUniformLocation: Option<WebGLUniformLocation>,
    readonly timeUniformLocation: Option<WebGLUniformLocation>
  ) {}
}

function loadProgram(gl: RenderingContext, source: string): Result<ProgramSpec, Error> {
  const vertexShaderSource = `
  #version 300 es
  in vec2 a_position;

  void main() {
      gl_Position = vec4(a_position, 0.0, 1.0);
  }
  `.trim();

  return compileProgram(gl, vertexShaderSource, source).map((programSpec) => {
    gl.enableVertexAttribArray(programSpec.positionAttributeLocation);
    gl.vertexAttribPointer(programSpec.positionAttributeLocation, 2, gl.FLOAT, false, 0, 0);
    gl.useProgram(programSpec.program);
    return programSpec;
  });
}

function compileProgram(
  gl: RenderingContext,
  vertexShaderSource: string,
  fragmentShaderSource: string
): Result<ProgramSpec, Error> {
  const compiledProgram = asResult(gl.createProgram(), Error('ProgramCreateError'))
    .andThen((program) => {
      return loadShader(gl, gl.VERTEX_SHADER, vertexShaderSource).andThen((vs) => {
        gl.attachShader(program, vs);
        return Ok(program);
      });
    })
    .andThen((program) => {
      return loadShader(gl, gl.FRAGMENT_SHADER, fragmentShaderSource).andThen((fs) => {
        gl.attachShader(program, fs);
        return Ok(program);
      });
    })
    .andThen((program) => {
      gl.linkProgram(program);
      if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
        return Err(Error('ProgramLinkError'));
      }
      return Ok(program);
    })
    .andThen((program) => {
      const positionAttributeLocation = gl.getAttribLocation(program, 'a_position');
      if (positionAttributeLocation < 0) {
        return Err(Error('PositionAttributeError'));
      }

      // Note: For the uniforms, if they are not used in the shader code, they will be
      // optimized out when compiling and the retrieved locations of them will be null.
      const resolutionUniformLocation = asOption(gl.getUniformLocation(program, 'u_resolution'));
      const timeUniformLocation = asOption(gl.getUniformLocation(program, 'u_time'));

      const programSpec = new ProgramSpec(
        program,
        positionAttributeLocation,
        resolutionUniformLocation,
        timeUniformLocation
      );

      return Ok(programSpec);
    });

  return compiledProgram;
}

class ShaderCompileError extends Error {
  info: string;

  constructor(info: string) {
    super();
    this.name = 'ShaderCompileError';
    this.info = info;
  }
}

function loadShader(
  gl: RenderingContext,
  type: RenderingContext['VERTEX_SHADER'] | RenderingContext['FRAGMENT_SHADER'],
  source: string
): Result<WebGLShader, Error> {
  const shader = gl.createShader(type);
  if (!shader) {
    return Err(Error('ShaderCreateError'));
  }

  gl.shaderSource(shader, source);
  gl.compileShader(shader);
  if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
    const info = asOption(gl.getShaderInfoLog(shader)).unwrapOr('');
    gl.deleteShader(shader);
    return Err(new ShaderCompileError(info));
  }

  return Ok(shader);
}

function initVertexData(gl: RenderingContext) {
  gl.bindVertexArray(gl.createVertexArray());
  gl.bindBuffer(gl.ARRAY_BUFFER, gl.createBuffer());
  gl.bufferData(
    gl.ARRAY_BUFFER,
    new Float32Array([
      // Triangle 1.
      -1, -1, 1, -1, -1, 1,

      // Triangle 2.
      -1, 1, 1, -1, 1, 1
    ]),
    gl.STATIC_DRAW
  );
}

class FpsCounter {
  frameCount: number;
  lastTime: number;
  fps: number;

  constructor() {
    this.frameCount = 0;
    this.lastTime = performance.now();
    this.fps = 0;
  }

  public update(): void {
    this.frameCount += 1;
    const currentTime = performance.now();
    const delta = currentTime - this.lastTime;
    if (delta > 1000) {
      this.fps = (this.frameCount * 1000) / delta;
      this.frameCount = 0;
      this.lastTime = currentTime;
    }
  }
}

export { Renderer, ShaderCompileError };
