import { DynamicField } from './fomrBuilderModel';

export interface ColumnDefinition {
  key: string;
  label: string;
  type?: 'text' | 'number' | 'date' | 'boolean' | 'select' | 'currency' | 'custom' | 'action';
  sortable?: boolean;
  filterable?: boolean;
  width?: string;
  minWidth?: string;
  maxWidth?: string;
  align?: 'left' | 'center' | 'right';
  format?: string;
  filterType?: 'text' | 'select' | 'date' | 'number' | 'range' | 'boolean' | 'multi-select';
  filterOptions?: { value: any; label: string }[];
  customFilter?: (item: any, filterValue: any) => boolean;
  renderer?: (value: any, row?: any) => any;
  hidden?: boolean;
  pinned?: 'left' | 'right' | null;
  cellClass?: string;
  headerClass?: string;
  resizable?: boolean;
  searchable?: boolean;
  editable?: boolean;
  required?: boolean;
  validation?: (value: any) => string | null;
  tooltip?: string;
  order?: number;
  className?: string;
}

export interface SortConfig {
  column: string;
  direction: 'asc' | 'desc';
}

export interface PaginationConfig {
  pageSize: number;
  currentPage: number;
  totalItems: number;
  pageSizeOptions?: number[];
  showFirstLast?: boolean;
  showPageNumbers?: boolean;
}

export interface DataTableConfig {
  columns: ColumnDefinition[];
  sort?: SortConfig;
  filters?: DynamicField[];
  rowActions?: RowAction[];
  headerActions?: RowAction[];
  selectable?: boolean;
  multiSelect?: boolean;
  showCheckboxes?: boolean;
  totalRecords?: number;
  loading?: boolean;
  error?: string | null;
  emptyMessage?: string;
  emptySubMessage?: string;
  rowClass?: (row: any) => string;
  rowStyle?: (row: any) => any;
  onRowClick?: (row: any) => void;
  onRowSelect?: (selectedRows: any[]) => void;
  onSort?: (sort: SortConfig) => void;
  onFilter?: (filters: any) => void;
  onPageChange?: (page: number) => void;
  onPageSizeChange?: (pageSize: number) => void;
  onRefresh?: () => void;
  onExport?: (format: 'csv' | 'excel' | 'pdf') => void;
  onEdit?: (row: any) => void;
  onDelete?: (row: any) => void;
  onAdd?: () => void;
}

export interface RowAction {
  label: string;
  icon: string; // FontAwesome icon name
  action: (row: any) => void;
  color?: 'primary' | 'danger' | 'warning' | 'success' | 'info' | 'secondary';
  disabled?: (row: any) => boolean;
  hidden?: (row: any) => boolean;
  rowType?: 'single' | 'multiple';
  class?: string;
  tooltip?: string;
  confirm?: {
    title: string;
    message: string;
    confirmText?: string;
    cancelText?: string;
  };
}

export interface TableEvent {
  type:
    | 'page'
    | 'sort'
    | 'filter'
    | 'refresh'
    | 'select'
    | 'rowClick'
    | 'export'
    | 'edit'
    | 'delete'
    | 'add'
    | 'pageSize';
  data: any;
}

export interface FilterState {
  [key: string]: any;
}

export interface SelectionState {
  selectedRows: any[];
  allSelected: boolean;
}

export interface TableState {
  sort: SortConfig | null;
  filters: FilterState;
  selection: SelectionState;
}
