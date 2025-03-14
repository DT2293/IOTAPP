const jwt = require("jsonwebtoken");

const authMiddleware = (req, res, next) => {
    const token = req.header("Authorization");
    if (!token) {
        return res.status(401).json({ error: "Truy cập bị từ chối, không có token!" });
    }

    try {
        const decoded = jwt.verify(token.replace("Bearer ", ""), "SECRET_KEY");
        req.user = decoded; // Gán thông tin user từ token
        next();
    } catch (error) {
        res.status(401).json({ error: "Token không hợp lệ!" });
    }
};

module.exports = authMiddleware;
