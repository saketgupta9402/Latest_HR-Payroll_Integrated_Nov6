import { useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Download, Receipt } from "lucide-react";
import { toast } from "sonner";

export const PayslipsTab = () => {
  const { data, isLoading } = useQuery({
    queryKey: ["my-payslips"],
    queryFn: async () => {
      const result = await api.payslips.list();
      return result.payslips || [];
    },
  });

  if (isLoading) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-24 w-full" />
        <Skeleton className="h-24 w-full" />
      </div>
    );
  }

  if (!data || data.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Receipt className="h-5 w-5" />
            Payslips
          </CardTitle>
          <CardDescription>No payslips available yet.</CardDescription>
        </CardHeader>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      {data.map((payslip: any) => {
        const monthName = new Date(2000, (payslip.payroll_cycles?.month || payslip.month || 1) - 1).toLocaleString(
          "default",
          { month: "long" },
        );
        const year = payslip.payroll_cycles?.year || payslip.year;

        return (
          <Card key={payslip.id} className="border">
            <CardHeader className="pb-2">
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle className="text-base">{monthName} {year}</CardTitle>
                  <CardDescription>
                    Gross: ₹{Number(payslip.gross_salary || 0).toLocaleString("en-IN")} • Net Salary: ₹
                    {Number(payslip.net_salary || 0).toLocaleString("en-IN")}
                  </CardDescription>
                </div>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={async () => {
                    try {
                      await api.payslips.downloadPDF(payslip.id);
                    } catch (err: any) {
                      toast.error(err.message || "Failed to download payslip");
                    }
                  }}
                >
                  <Download className="h-4 w-4 mr-2" />
                  Download
                </Button>
              </div>
            </CardHeader>
            <CardContent className="text-sm text-muted-foreground">
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div>
                  <span className="font-medium text-foreground">Gross Salary</span>
                  <p>₹{Number(payslip.gross_salary || 0).toLocaleString("en-IN")}</p>
                </div>
                <div>
                  <span className="font-medium text-foreground">Total Deductions</span>
                  <p>₹{Number(payslip.deductions || 0).toLocaleString("en-IN")}</p>
                </div>
                <div>
                  <span className="font-medium text-foreground">Net Salary</span>
                  <p>₹{Number(payslip.net_salary || 0).toLocaleString("en-IN")}</p>
                </div>
                <div>
                  <span className="font-medium text-foreground">LOP Days</span>
                  <p>{payslip.lop_days || 0}</p>
                </div>
              </div>
            </CardContent>
          </Card>
        );
      })}
    </div>
  );
};


