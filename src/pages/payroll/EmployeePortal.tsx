import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { api } from "@/lib/api";
import { DollarSign, LogOut, Receipt, FileText } from "lucide-react";
import { toast } from "sonner";
import { EmployeeSalaryStructure } from "@/components/payroll/employees/EmployeeSalaryStructure";
import { PayslipsTab } from "@/components/payroll/employee-portal/PayslipsTab";
import { TaxDeclarationsTab } from "@/components/payroll/employee-portal/TaxDeclarationsTab";
import { TaxDocumentsTab } from "@/components/payroll/employee-portal/TaxDocumentsTab";
import { LeaveRequestsTab } from "@/components/payroll/employee-portal/LeaveRequestsTab";
import { AttendanceTab } from "@/components/payroll/employee-portal/AttendanceTab";

const PayrollEmployeePortal = () => {
  const navigate = useNavigate();
  const [user, setUser] = useState<any>(null);
  const [employee, setEmployee] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const session = await api.auth.session();
        if (!session?.session) {
          navigate("/payroll/auth");
          return;
        }
        setUser({ id: session.session.userId });

        const me = await api.me.employee();
        if (me.employee) {
          setEmployee(me.employee);
        } else {
          navigate("/payroll/dashboard");
          return;
        }
      } catch (error: any) {
        toast.error(`Session error: ${error.message}`);
        navigate("/payroll/auth");
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [navigate]);

  const handleSignOut = async () => {
    try {
      await api.auth.logout();
      toast.success("Signed out successfully");
      navigate("/payroll/auth");
    } catch (error: any) {
      toast.error(`Sign out failed: ${error.message}`);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 via-background to-accent/5">
      <header className="border-b bg-card/50 backdrop-blur-sm sticky top-0 z-10">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-foreground">Employee Portal</h1>
              <p className="text-muted-foreground">Welcome, {employee?.full_name || user?.id}</p>
            </div>
            <Button variant="ghost" onClick={handleSignOut}>
              <LogOut className="mr-2 h-4 w-4" />
              Sign Out
            </Button>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8">
        {!employee ? (
          <Card>
            <CardHeader>
              <CardTitle>Profile Not Found</CardTitle>
              <CardDescription>Your employee profile is not set up yet. Please contact HR.</CardDescription>
            </CardHeader>
          </Card>
        ) : (
          <Tabs defaultValue="overview" className="w-full">
            <TabsList className="grid w-full grid-cols-7">
              <TabsTrigger value="overview">Overview</TabsTrigger>
              <TabsTrigger value="salary">Salary</TabsTrigger>
              <TabsTrigger value="payslips">Payslips</TabsTrigger>
              <TabsTrigger value="leaves">Leaves</TabsTrigger>
              <TabsTrigger value="attendance">Attendance</TabsTrigger>
              <TabsTrigger value="declarations">Declarations</TabsTrigger>
              <TabsTrigger value="documents">Documents</TabsTrigger>
            </TabsList>

            <TabsContent value="overview" className="space-y-6">
              <Card>
                <CardHeader>
                  <CardTitle>Welcome to Your Portal</CardTitle>
                  <CardDescription>Quick overview of your employee information</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <p className="text-sm text-muted-foreground">Employee Code</p>
                      <p className="font-semibold">{employee.employee_code}</p>
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">Email</p>
                      <p className="font-semibold">{employee.email}</p>
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">Department</p>
                      <p className="font-semibold">{employee.department || "-"}</p>
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">Designation</p>
                      <p className="font-semibold">{employee.designation || "-"}</p>
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">Date of Joining</p>
                      <p className="font-semibold">
                        {employee.date_of_joining ? new Date(employee.date_of_joining).toLocaleDateString("en-IN") : "-"}
                      </p>
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">Status</p>
                      <p className="font-semibold capitalize">{employee.status}</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="salary">
              <EmployeeSalaryStructure />
            </TabsContent>

            <TabsContent value="payslips">
              <PayslipsTab />
            </TabsContent>

            <TabsContent value="leaves">
              <LeaveRequestsTab />
            </TabsContent>

            <TabsContent value="attendance">
              <AttendanceTab />
            </TabsContent>

            <TabsContent value="declarations">
              <TaxDeclarationsTab />
            </TabsContent>

            <TabsContent value="documents">
              <TaxDocumentsTab />
            </TabsContent>
          </Tabs>
        )}
      </main>
    </div>
  );
};

export default PayrollEmployeePortal;

