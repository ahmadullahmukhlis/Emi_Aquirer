export interface SidebarItem {
  id: number;
  label: string;
  icon: string;
  route?: string;
  isActive: boolean;
  isExpanded?: boolean;
  children?: SidebarItem[];
  badge?: {
    text: string;
    color: string;
  };
}