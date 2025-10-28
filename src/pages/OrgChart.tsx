import { AppLayout } from "@/components/layout/AppLayout";
import OrgChartComponent from "@/components/org-chart/OrgChart";

export default function OrgChartPage() {
  return (
    <AppLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold">Organization Chart</h1>
          <p className="text-muted-foreground">View your organization's reporting structure</p>
        </div>

        <OrgChartComponent />
      </div>
    </AppLayout>
  );
}
