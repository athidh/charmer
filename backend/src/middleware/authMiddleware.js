const jwt = require('jsonwebtoken');

const protect = (req, res, next) => {
    try {
        // 1. Get the token from the 'Authorization' header
        // Expecting format: "Bearer <token>"
        const authHeader = req.headers.authorization;
        const token = authHeader && authHeader.split(' ')[1];

        if (!token) {
            return res.status(401).json({ message: "Access denied. No token provided." });
        }

        // 2. Verify the token using your secret key
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // 3. Attach the decoded user data (ID, role) to the request object
        // This allows your controllers to know WHO is making the request
        req.user = decoded;

        // 4. Pass control to the next function (the controller)
        next();
    } catch (err) {
        res.status(403).json({ message: "Invalid or expired token." });
    }
};

module.exports = { protect };