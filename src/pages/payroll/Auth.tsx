import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { toast } from "sonner";
import { Building2, Lock, Mail } from "lucide-react";

const PayrollAuth = () => {
  const navigate = useNavigate();
  const [isLoading, setIsLoading] = useState(false);
  const [email, setEmail] = useState("");
  const [pin, setPin] = useState("");

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    if (pin.length !== 6 || !/^\d{6}$/.test(pin)) {
      toast.error("Please enter a valid 6-digit PIN");
      setIsLoading(false);
      return;
    }

    try {
      await api.auth.loginWithPin(email, pin);
      const profile = await api.me.profile();
      const me = await api.me.employee();

      if (me?.employee) {
        navigate("/payroll/employee-portal");
      } else if (profile?.profile?.tenant_id) {
        navigate("/payroll/dashboard");
      } else {
        navigate("/payroll/dashboard");
      }
      toast.success("Welcome back!");
    } catch (error: any) {
      toast.error(error.message || "Sign in failed");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary/5 via-background to-accent/5 p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-primary mb-4">
            <Building2 className="w-8 h-8 text-primary-foreground" />
          </div>
          <h1 className="text-3xl font-bold text-foreground mb-2">PayrollPro</h1>
          <p className="text-muted-foreground">Access your payroll with your 6-digit PIN</p>
        </div>

        <Card className="shadow-xl">
          <CardHeader>
            <CardTitle>Sign In</CardTitle>
            <CardDescription>
              Sign up in the HR Portal to access Payroll. Use your email and 6-digit PIN to sign in.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSignIn} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="email">Email</Label>
                <div className="relative">
                  <Mail className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                  <Input
                    id="email"
                    type="email"
                    placeholder="you@company.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                    className="pl-10"
                  />
                </div>
              </div>
              <div className="space-y-2">
                <Label htmlFor="pin">6-Digit PIN</Label>
                <div className="relative">
                  <Lock className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                  <Input
                    id="pin"
                    type="password"
                    placeholder="000000"
                    value={pin}
                    onChange={(e) => {
                      const value = e.target.value.replace(/\D/g, '').slice(0, 6);
                      setPin(value);
                    }}
                    required
                    maxLength={6}
                    className="pl-10 text-center text-2xl tracking-widest"
                    inputMode="numeric"
                  />
                </div>
                <p className="text-xs text-muted-foreground">
                  Enter your 6-digit authentication PIN
                </p>
              </div>
              <Button type="submit" className="w-full" disabled={isLoading}>
                {isLoading ? "Signing in..." : "Sign In"}
              </Button>
              <div className="text-center text-sm text-muted-foreground mt-4">
                <p>Don't have a PIN? Sign up in the HR Portal first.</p>
                <p className="mt-2">First-time users will be prompted to set up their PIN.</p>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default PayrollAuth;

