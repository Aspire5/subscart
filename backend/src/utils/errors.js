/**
 * Custom application error class for business rule validation failures.
 * Used to return semantic HTTP 4xx error codes rather than 500 internal server errors.
 */
export class AppError extends Error {
  constructor(message, statusCode = 400) {
    super(message);
    this.statusCode = statusCode;
    this.name = 'AppError';
    Error.captureStackTrace?.(this, this.constructor);
  }
}
