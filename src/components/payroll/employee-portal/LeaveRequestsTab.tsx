import { useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { format } from "date-fns";
import { CalendarDays, Clock, FileText } from "lucide-react";

const getStatusVariant = (status: string) => {
  switch (status) {
    case "approved":
      return "default" as const;
    case "pending":
      return "outline" as const;
    case "rejected":
      return "destructive" as const;
    default:
      return "secondary" as const;
  }
};

const getLeaveTypeLabel = (type: string) => {
  switch (type) {
    case "sick":
      return "Sick Leave";
    case "casual":
      return "Casual Leave";
    case "earned":
      return "Earned Leave";
    case "loss_of_pay":
      return "Loss of Pay";
    case "other":
      return "Other Leave";
    default:
      return type;
  }
};

export const LeaveRequestsTab = () => {
  const { data, isLoading } = useQuery({
    queryKey: ["my-leaves"],
    queryFn: async () => {
      const result = await api.leaves.getMyLeaves();
      return result.leaveRequests || [];
    },
  });

  if (isLoading) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-40 w-full" />
        <Skeleton className="h-40 w-full" />
      </div>
    );
  }

  if (!data || data.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <CalendarDays className="h-5 w-5" />
            Leave Requests
          </CardTitle>
          <CardDescription>No leave records available yet.</CardDescription>
        </CardHeader>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      {data.map((leave: any) => {
        const start = leave.start_date ? format(new Date(leave.start_date), "dd MMM yyyy") : "-";
        const end = leave.end_date ? format(new Date(leave.end_date), "dd MMM yyyy") : "-";

        return (
          <Card key={leave.id} className="border">
            <CardHeader className="pb-2">
              <div className="flex items-center justify-between">
                <div className="space-y-1">
                  <CardTitle className="flex items-center gap-2 text-base">
                    <FileText className="h-4 w-4 text-primary" />
                    {getLeaveTypeLabel(leave.leave_type || "other")}
                  </CardTitle>
                  <CardDescription className="flex items-center gap-2 text-sm">
                    <CalendarDays className="h-4 w-4" />
                    {start} - {end}
                    <Clock className="h-4 w-4" />
                    {leave.days || 0} day(s)
                  </CardDescription>
                </div>
                <div className="flex flex-col items-end gap-2">
                  <Badge variant={getStatusVariant(leave.status)} className="uppercase">
                    {leave.status || "pending"}
                  </Badge>
                  {leave.approved_by_name && (
                    <span className="text-xs text-muted-foreground">Reviewed by {leave.approved_by_name}</span>
                  )}
                </div>
              </div>
            </CardHeader>
            <CardContent className="pt-0 text-sm text-muted-foreground space-y-2">
              {leave.reason && <p><span className="font-medium text-foreground">Reason:</span> {leave.reason}</p>}
              {leave.status === "rejected" && leave.rejection_reason && (
                <p className="text-destructive">
                  <span className="font-medium">Rejection note:</span> {leave.rejection_reason}
                </p>
              )}
            </CardContent>
          </Card>
        );
      })}
    </div>
  );
};


