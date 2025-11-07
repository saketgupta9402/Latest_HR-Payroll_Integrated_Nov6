import { useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Button } from "@/components/ui/button";
import { DownloadCloud, FileText } from "lucide-react";
import { toast } from "sonner";

export const TaxDocumentsTab = () => {
  const { data, isLoading } = useQuery({
    queryKey: ["tax-documents"],
    queryFn: async () => {
      const result = await api.tax.getDocuments();
      return result.taxDocuments || [];
    },
  });

  if (isLoading) {
    return <Skeleton className="h-32 w-full" />;
  }

  if (!data || data.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <FileText className="h-5 w-5" />
            Tax Documents
          </CardTitle>
          <CardDescription>No tax documents have been uploaded yet.</CardDescription>
        </CardHeader>
      </Card>
    );
  }

  return (
    <div className="grid gap-4 md:grid-cols-2">
      {data.map((doc: any) => (
        <Card key={doc.id} className="border">
          <CardHeader className="pb-2">
            <CardTitle className="text-base flex items-center gap-2">
              <FileText className="h-4 w-4 text-primary" />
              {doc.document_type || "Document"}
            </CardTitle>
            <CardDescription>{doc.file_name}</CardDescription>
          </CardHeader>
          <CardContent className="flex items-center justify-between">
            <div className="text-sm text-muted-foreground">
              Uploaded on {new Date(doc.uploaded_at).toLocaleDateString("en-IN")}
            </div>
            <Button
              variant="outline"
              size="sm"
              onClick={() => {
                try {
                  window.open(doc.file_url, "_blank", "noreferrer");
                } catch (err: any) {
                  toast.error(err.message || "Failed to download document");
                }
              }}
            >
              <DownloadCloud className="h-4 w-4 mr-2" />
              Download
            </Button>
          </CardContent>
        </Card>
      ))}
    </div>
  );
};


