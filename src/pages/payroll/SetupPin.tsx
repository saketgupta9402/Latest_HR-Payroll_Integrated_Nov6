import { useState, useEffect } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { toast } from "sonner";
import { Lock, Shield } from "lucide-react";

const PayrollSetupPin = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [isLoading, setIsLoading] = useState(false);
  const [pin, setPin] = useState("");
  const [confirmPin, setConfirmPin] = useState("");
  const [email, setEmail] = useState("");

  useEffect(() => {
    const emailParam = searchParams.get("email");
    if (emailParam) {
      setEmail(emailParam);
    } else {
      api.auth
        .session()
        .then((session) => {
          if (session?.session) {
            api.me
              .profile()
              .then((profile) => {
                if (profile?.profile?.email) {
                  setEmail(profile.profile.email);
                }
              })
              .catch(() => {
                toast.error("Unable to retrieve email. Please sign in again.");
                navigate("/payroll/auth");
              });
          } else {
            toast.error("Session expired. Please sign in again.");
            navigate("/payroll/auth");
          }
        })
        .catch(() => {
          toast.error("Please sign in through the HR Portal first.");
          navigate("/payroll/auth");
        });
    }
  }, [searchParams, navigate]);

  const handleSetupPin = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    if (pin.length !== 6 || !/^\d{6}$/.test(pin)) {
      toast.error("PIN must be exactly 6 digits");
      setIsLoading(false);
      return;
    }

    if (pin !== confirmPin) {
      toast.error("PINs do not match");
      setIsLoading(false);
      return;
    }

    if (!email) {
      toast.error("Email is required");
      setIsLoading(false);
      return;
    }

    try {
      await api.auth.setupPin(email, pin);
      toast.success("PIN set successfully!");

      const me = await api.me.employee();
      if (me?.employee) {
        navigate("/payroll/employee-portal");
      } else {
        navigate("/payroll/dashboard");
      }
    } catch (error: any) {
      toast.error(error.message || "Failed to set PIN");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary/5 via-background to-accent/5 p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-primary mb-4">
            <Shield className="w-8 h-8 text-primary-foreground" />
          </div>
          <h1 className="text-3xl font-bold text-foreground mb-2">Set Up Your PIN</h1>
          <p className="text-muted-foreground">Create a 6-digit PIN to secure your payroll access</p>
        </div>

        <Card className="shadow-xl">
          <CardHeader>
            <CardTitle>PIN Setup</CardTitle>
            <CardDescription>
              Choose a 6-digit PIN that you'll use to sign in to the Payroll system. Make sure it's something you can remember!
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSetupPin} className="space-y-4">
              {email && (
                <div className="space-y-2">
                  <Label>Email</Label>
                  <Input type="email" value={email} disabled className="bg-muted" />
                </div>
              )}

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
                      const value = e.target.value.replace(/\D/g, "").slice(0, 6);
                      setPin(value);
                    }}
                    required
                    maxLength={6}
                    className="pl-10 text-center text-2xl tracking-widest"
                    inputMode="numeric"
                    autoFocus
                  />
                </div>
                <p className="text-xs text-muted-foreground">Enter a 6-digit PIN</p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="confirm-pin">Confirm PIN</Label>
                <div className="relative">
                  <Lock className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                  <Input
                    id="confirm-pin"
                    type="password"
                    placeholder="000000"
                    value={confirmPin}
                    onChange={(e) => {
                      const value = e.target.value.replace(/\D/g, "").slice(0, 6);
                      setConfirmPin(value);
                    }}
                    required
                    maxLength={6}
                    className="pl-10 text-center text-2xl tracking-widest"
                    inputMode="numeric"
                  />
                </div>
                <p className="text-xs text-muted-foreground">Re-enter your PIN to confirm</p>
              </div>

              <Button type="submit" className="w-full" disabled={isLoading || !email}>
                {isLoading ? "Setting up PIN..." : "Set Up PIN"}
              </Button>

              <div className="text-center text-sm text-muted-foreground mt-4">
                <p>You'll use this PIN to sign in to the Payroll system.</p>
                <p className="mt-2 text-xs">Make sure to remember it or store it securely.</p>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default PayrollSetupPin;

