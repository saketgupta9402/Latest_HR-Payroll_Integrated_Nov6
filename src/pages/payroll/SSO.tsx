import { useEffect, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { toast } from "sonner";
import { Loader2 } from "lucide-react";
import { api } from "@/lib/api";

const PayrollSSO = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [status, setStatus] = useState<"processing" | "error">("processing");
  const [errorMessage, setErrorMessage] = useState<string>("");

  useEffect(() => {
    const processSSO = async () => {
      const token = searchParams.get("token");

      if (!token) {
        setStatus("error");
        setErrorMessage("Missing SSO token. Please try logging in again.");
        toast.error("Missing SSO token");
        setTimeout(() => navigate("/payroll/auth"), 3000);
        return;
      }

      try {
        const apiUrl = import.meta.env.VITE_API_URL || "http://localhost:3001";
        const response = await fetch(`${apiUrl}/api/payroll/sso?token=${encodeURIComponent(token)}`, {
          method: "GET",
          credentials: "include",
          headers: {
            "Content-Type": "application/json",
          },
        });

        if (!response.ok) {
          const errorData = await response.json().catch(() => ({ error: "SSO failed" }));
          throw new Error(errorData.error || errorData.message || "SSO authentication failed");
        }

        if (response.redirected) {
          window.location.href = response.url;
          return;
        }

        const data = await response.json().catch(() => null);

        if (data?.token) {
          api.setToken(data.token);
        }

        if (data?.redirect) {
          if (data.requiresPinSetup) {
            toast.info("Please set up your PIN to continue");
          } else {
            toast.success("Successfully signed in!");
          }
          navigate(data.redirect);
          return;
        }

        const session = await api.auth.session();
        if (session?.session) {
          const employeeData = await api.me.employee();
          if (employeeData?.employee) {
            navigate("/payroll/employee-portal");
          } else {
            navigate("/payroll/dashboard");
          }
          toast.success("Successfully signed in!");
        } else {
          throw new Error("Session not established");
        }
      } catch (error: any) {
        console.error("SSO error:", error);
        setStatus("error");
        setErrorMessage(error.message || "Failed to complete SSO authentication");
        toast.error(error.message || "SSO authentication failed");
        setTimeout(() => navigate("/payroll/auth"), 5000);
      }
    };

    processSSO();
  }, [searchParams, navigate]);

  if (status === "processing") {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gray-100">
        <div className="text-center">
          <Loader2 className="mx-auto h-12 w-12 animate-spin text-primary mb-4" />
          <h2 className="text-2xl font-semibold mb-2">Completing sign-in...</h2>
          <p className="text-gray-600">Please wait while we authenticate you.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-100">
      <div className="text-center max-w-md">
        <div className="mb-4 text-red-600">
          <svg className="mx-auto h-12 w-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <h2 className="text-2xl font-semibold mb-2 text-gray-900">Authentication Failed</h2>
        <p className="text-gray-600 mb-4">{errorMessage}</p>
        <p className="text-sm text-gray-500">Redirecting to login page...</p>
      </div>
    </div>
  );
};

export default PayrollSSO;

