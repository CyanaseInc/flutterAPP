const errorHandler = (err, req, res, next) => {
  console.error(err.stack); // Log the error stack trace

  // Default error message and status code
  const statusCode = err.statusCode || 500;
  const message = err.message || "Internal Server Error";

  // Send the error response
  res.status(statusCode).json({
    success: false,
    message: message,
  });
};

module.exports = errorHandler;