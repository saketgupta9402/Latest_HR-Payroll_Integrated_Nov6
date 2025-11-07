import { withClient, query } from '../db/pool.js';

export async function upsertPayrollUser(hrUser) {
  return withClient(async (client) => {
    await client.query('BEGIN');

    try {
      let userResult = await client.query(
      `SELECT id, email, hr_user_id, org_id, payroll_role, first_name, last_name
       FROM users
       WHERE hr_user_id = $1`,
      [hrUser.hrUserId]
    );

      let user;

      if (userResult.rows.length > 0) {
        user = userResult.rows[0];

        const nameParts = hrUser.name.split(' ');
        const firstName = nameParts[0] || '';
        const lastName = nameParts.slice(1).join(' ') || '';

        await client.query(
        `UPDATE users
         SET email = $1,
             org_id = $2,
             payroll_role = $3,
             first_name = COALESCE($4, first_name),
             last_name = COALESCE($5, last_name),
             updated_at = now()
         WHERE hr_user_id = $6`,
        [
          hrUser.email,
          hrUser.orgId,
          hrUser.payrollRole,
          firstName,
          lastName,
          hrUser.hrUserId,
        ]
      );

        userResult = await client.query(
        `SELECT id, email, hr_user_id, org_id, payroll_role, first_name, last_name
         FROM users
         WHERE hr_user_id = $1`,
        [hrUser.hrUserId]
      );

        user = userResult.rows[0];
        console.log(`✓ Updated Payroll user: ${user.email} (${user.payroll_role})`);
      } else {
        const existingByEmail = await client.query(
        `SELECT id, email, hr_user_id, org_id, payroll_role
         FROM users
         WHERE email = $1`,
        [hrUser.email]
      );

        const nameParts = hrUser.name.split(' ');
        const firstName = nameParts[0] || '';
        const lastName = nameParts.slice(1).join(' ') || '';

        if (existingByEmail.rows.length > 0) {
          const existingUser = existingByEmail.rows[0];

          if (existingUser.hr_user_id && existingUser.hr_user_id !== hrUser.hrUserId) {
            console.warn(`⚠️  User ${hrUser.email} already linked to different HR user: ${existingUser.hr_user_id}`);
          }

          await client.query(
          `UPDATE users
           SET hr_user_id = $1,
               org_id = $2,
               payroll_role = $3,
               first_name = COALESCE($4, first_name),
               last_name = COALESCE($5, last_name),
               updated_at = now()
           WHERE email = $6`,
          [
            hrUser.hrUserId,
            hrUser.orgId,
            hrUser.payrollRole,
            firstName,
            lastName,
            hrUser.email,
          ]
        );

          userResult = await client.query(
          `SELECT id, email, hr_user_id, org_id, payroll_role, first_name, last_name
           FROM users
           WHERE hr_user_id = $1`,
          [hrUser.hrUserId]
        );

          user = userResult.rows[0];
          console.log(`✓ Linked Payroll user: ${user.email} → HR ID: ${hrUser.hrUserId} (${user.payroll_role})`);
        } else {
          const insertResult = await client.query(
          `INSERT INTO users (
            hr_user_id, email, org_id, payroll_role, first_name, last_name
          ) VALUES ($1, $2, $3, $4, $5, $6)
          RETURNING id, email, hr_user_id, org_id, payroll_role, first_name, last_name`,
          [
            hrUser.hrUserId,
            hrUser.email,
            hrUser.orgId,
            hrUser.payrollRole,
            firstName,
            lastName,
          ]
        );

          user = insertResult.rows[0];
          console.log(`✓ Created Payroll user: ${user.email} (${user.payroll_role})`);
        }
      }

      await client.query('COMMIT');
      return user;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    }

  });
}

export async function getPayrollUserByEmail(email) {
  const result = await query(
    `SELECT id, email, hr_user_id, org_id, payroll_role, first_name, last_name
     FROM users
     WHERE email = $1`,
    [email.toLowerCase().trim()]
  );
  return result.rows[0] || null;
}

