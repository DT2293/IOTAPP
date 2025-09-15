const jwt = require("jsonwebtoken");
require("dotenv").config();


const authMiddleware = (req, res, next) => {
    const token = req.header("Authorization");
    if (!token) {
        return res.status(401).json({ error: "Truy cập bị từ chối, không có token!" });
    }

    try {
      //  const decoded = jwt.verify(token.replace("Bearer ", ""), "SECRET_KEY");
      const decoded = jwt.verify(token.replace("Bearer ", ""), process.env.JWT_SECRET);

        req.user = decoded; 
        next();
    } catch (error) {
        res.status(401).json({ error: "Token không hợp lệ!" });
    }
};

module.exports = authMiddleware;

