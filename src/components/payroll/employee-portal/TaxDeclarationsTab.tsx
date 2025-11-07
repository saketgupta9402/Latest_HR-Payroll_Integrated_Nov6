import { useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import { FileText } from "lucide-react";
import { format } from "date-fns";

export const TaxDeclarationsTab = () => {
  const { data, isLoading } = useQuery({
    queryKey: ["tax-declarations"],
    queryFn: async () => {
      const result = await api.tax.getDeclarations();
      return result.taxDeclarations || [];
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
            <FileText className="h-5 w-5" />
            Tax Declarations
          </CardTitle>
          <CardDescription>No tax declarations have been submitted yet.</CardDescription>
        </CardHeader>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      {data.map((declaration: any) => (
        <Card key={declaration.id} className="border">
          <CardHeader className="pb-2">
            <div className="flex items-center justify-between">
              <div>
                <CardTitle className="text-base">Financial Year {declaration.financial_year}</CardTitle>
                <CardDescription>
                  Submitted on {format(new Date(declaration.created_at), "dd MMM yyyy")}
                </CardDescription>
              </div>
              <Badge variant="outline" className="uppercase">Total Deduction: ₹{Number(declaration.total_deductions || 0).toLocaleString("en-IN")}</Badge>
            </div>
          </CardHeader>
          <CardContent className="grid grid-cols-1 md:grid-cols-4 gap-4 text-sm text-muted-foreground">
            <div>
              <span className="font-medium text-foreground">Section 80C</span>
              <p>₹{Number(declaration.section_80c || 0).toLocaleString("en-IN")}</p>
            </div>
            <div>
              <span className="font-medium text-foreground">Section 80D</span>
              <p>₹{Number(declaration.section_80d || 0).toLocaleString("en-IN")}</p>
            </div>
            <div>
              <span className="font-medium text-foreground">Section 24B</span>
              <p>₹{Number(declaration.section_24b || 0).toLocaleString("en-IN")}</p>
            </div>
            <div>
              <span className="font-medium text-foreground">Other Deductions</span>
              <p>₹{Number(declaration.other_deductions || 0).toLocaleString("en-IN")}</p>
            </div>
          </CardContent>
        </Card>
      ))}
    </div>
  );
};


