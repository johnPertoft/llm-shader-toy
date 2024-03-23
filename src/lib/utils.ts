import { Err, None, Ok, Option, Result, Some } from 'ts-results';

function asResult<T>(value: T | null | undefined, err: Error): Result<T, Error> {
  if (value === null || value === undefined) {
    return Err(err);
  }
  return Ok(value);
}

function asOption<T>(value: T | null | undefined): Option<T> {
  if (value === null || value === undefined) {
    return None;
  }
  return Some(value);
}

export { asOption, asResult };
