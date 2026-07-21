function validate(schema) {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.body, { abortEarly: false, stripUnknown: true });

    if (error) {
      const messages = error.details.map(d => d.message).join('; ');
      return res.status(400).json({ success: false, message: messages });
    }

    req.body = value;
    next();
  };
}

function validateQuery(schema) {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.query, { abortEarly: false, stripUnknown: true, convert: true });

    if (error) {
      const messages = error.details.map(d => d.message).join('; ');
      return res.status(400).json({ success: false, message: messages });
    }

    req.query = value;
    next();
  };
}

module.exports = { validate, validateQuery };
