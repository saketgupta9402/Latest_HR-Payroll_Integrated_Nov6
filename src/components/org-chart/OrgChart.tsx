import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent } from "@/components/ui/card";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { User } from "lucide-react";

interface Employee {
  id: string;
  employee_id: string;
  position: string;
  profiles: {
    first_name: string;
    last_name: string;
    email: string;
  };
  reporting_manager_id: string | null;
}

interface TreeNode extends Employee {
  children: TreeNode[];
}

export default function OrgChart() {
  const [tree, setTree] = useState<TreeNode[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchOrgStructure();
  }, []);

  const fetchOrgStructure = async () => {
    const { data: employees } = await supabase
      .from('employees')
      .select(`
        id,
        employee_id,
        position,
        reporting_manager_id,
        profiles!employees_user_id_fkey(first_name, last_name, email)
      `)
      .eq('status', 'active');

    if (employees) {
      const orgTree = buildTree(employees as any);
      setTree(orgTree);
    }
    setLoading(false);
  };

  const buildTree = (employees: Employee[]): TreeNode[] => {
    const map: Record<string, TreeNode> = {};
    const roots: TreeNode[] = [];

    // Create all nodes
    employees.forEach(emp => {
      map[emp.id] = { ...emp, children: [] };
    });

    // Build tree structure
    employees.forEach(emp => {
      const node = map[emp.id];
      if (emp.reporting_manager_id && map[emp.reporting_manager_id]) {
        map[emp.reporting_manager_id].children.push(node);
      } else {
        roots.push(node);
      }
    });

    return roots;
  };

  const renderNode = (node: TreeNode, level: number = 0) => {
    const initials = `${node.profiles.first_name[0]}${node.profiles.last_name[0]}`;
    
    return (
      <div key={node.id} className="flex flex-col items-center">
        <Card className="w-64 mb-4 transition-all hover:shadow-medium">
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <Avatar className="h-12 w-12">
                <AvatarFallback className="bg-primary/10 text-primary">
                  {initials}
                </AvatarFallback>
              </Avatar>
              <div className="flex-1 min-w-0">
                <p className="font-semibold text-sm truncate">
                  {node.profiles.first_name} {node.profiles.last_name}
                </p>
                <p className="text-xs text-muted-foreground truncate">{node.position}</p>
                <p className="text-xs text-muted-foreground/60 truncate">{node.employee_id}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        
        {node.children.length > 0 && (
          <div className="relative">
            {/* Vertical line to children */}
            <div className="absolute left-1/2 -translate-x-1/2 w-0.5 h-8 bg-border" />
            
            <div className="flex gap-8 pt-8">
              {node.children.map(child => (
                <div key={child.id} className="relative">
                  {/* Horizontal line from parent */}
                  <div className="absolute -top-8 left-1/2 -translate-x-1/2 w-0.5 h-8 bg-border" />
                  {renderNode(child, level + 1)}
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    );
  };

  if (loading) {
    return <div className="text-center py-12">Loading organization chart...</div>;
  }

  if (tree.length === 0) {
    return (
      <div className="text-center py-12 text-muted-foreground">
        <User className="h-12 w-12 mx-auto mb-4 opacity-50" />
        <p>No organizational structure found</p>
        <p className="text-sm mt-2">Add employees and assign reporting managers to see the org chart</p>
      </div>
    );
  }

  return (
    <div className="w-full overflow-x-auto py-8">
      <div className="flex flex-col items-center gap-8 min-w-max px-8">
        {tree.map(node => renderNode(node))}
      </div>
    </div>
  );
}
