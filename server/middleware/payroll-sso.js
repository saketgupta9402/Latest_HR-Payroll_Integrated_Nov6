import jwt from 'jsonwebtoken';

function mapHrToPayrollRole(hrRoles = []) {
  const adminSet = new Set(['CEO', 'Admin', 'HR', 'ceo', 'admin', 'hr']);
  return hrRoles.some((role) => adminSet.has(role)) ? 'payroll_admin' : 'payroll_employee';
}

export async function verifyHrSsoToken(req, res, next) {
  try {
    const token = (req.query.token || req.headers.authorization?.replace('Bearer ', '') || '').toString();

    if (!token) {
      return res.status(401).json({
        error: 'SSO token required',
        message: 'Please provide a valid SSO token from HR system',
      });
    }

    const secret =
      process.env.HR_JWT_SECRET ||
      process.env.PAYROLL_JWT_SECRET ||
      process.env.JWT_SECRET ||
      'your-shared-secret-key';

    if (!secret || secret === 'your-shared-secret-key') {
      console.error('⚠️  HR_JWT_SECRET not configured. Set HR_JWT_SECRET environment variable.');
      return res.status(500).json({
        error: 'SSO configuration error',
        message: 'JWT secret not configured',
      });
    }

    let payload;
    try {
      payload = jwt.verify(token, secret);
    } catch (jwtError) {
      if (jwtError.name === 'TokenExpiredError') {
        return res.status(401).json({
          error: 'Token expired',
          message: 'SSO token has expired. Please try again from HR system.',
        });
      }
      if (jwtError.name === 'JsonWebTokenError') {
        return res.status(401).json({
          error: 'Invalid token',
          message: 'SSO token is invalid or malformed',
        });
      }
      throw jwtError;
    }

    if (payload.iss !== 'hr-app') {
      return res.status(401).json({
        error: 'Invalid token issuer',
        message: `Expected issuer 'hr-app', got '${payload.iss}'`,
      });
    }

    if (payload.aud !== 'payroll-app') {
      return res.status(401).json({
        error: 'Invalid token audience',
        message: `Expected audience 'payroll-app', got '${payload.aud}'`,
      });
    }

    if (payload.exp && payload.exp < Math.floor(Date.now() / 1000)) {
      return res.status(401).json({
        error: 'Token expired',
        message: 'SSO token has expired',
      });
    }

    const hrUserId = payload.sub;
    const orgId = payload.org_id;
    const email = payload.email;
    const name = payload.name || email;
    const roles = payload.roles || [];
    const payrollRole = payload.payroll_role || mapHrToPayrollRole(roles);

    if (!hrUserId || !orgId || !email) {
      return res.status(401).json({
        error: 'Invalid token claims',
        message: 'Token missing required claims: sub, org_id, or email',
      });
    }

    req.hrUser = {
      hrUserId: hrUserId.toString(),
      orgId: orgId.toString(),
      email: email.toLowerCase().trim(),
      name,
      roles,
      payrollRole,
    };

    console.log(`✅ SSO token verified: ${email} (${payrollRole}) from org ${orgId}`);

    next();
  } catch (error) {
    console.error('SSO verification error:', error);
    return res.status(500).json({
      error: 'SSO verification failed',
      message: error.message || 'Internal server error during SSO verification',
    });
  }
}

