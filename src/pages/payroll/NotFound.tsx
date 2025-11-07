import { useLocation } from "react-router-dom";
import { useEffect } from "react";

const PayrollNotFound = () => {
  const location = useLocation();

  useEffect(() => {
    console.error("Payroll 404: attempted to access", location.pathname);
  }, [location.pathname]);

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-100">
      <div className="text-center">
        <h1 className="mb-4 text-4xl font-bold">404</h1>
        <p className="mb-4 text-xl text-gray-600">Oops! Payroll page not found</p>
        <a href="/payroll" className="text-blue-500 underline hover:text-blue-700">
          Return to Payroll Home
        </a>
      </div>
    </div>
  );
};

export default PayrollNotFound;

