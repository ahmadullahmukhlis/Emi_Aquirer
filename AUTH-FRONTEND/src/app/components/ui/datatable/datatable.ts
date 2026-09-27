import { Message } from './../../../../../node_modules/esbuild/lib/main.d';
import { ToastService } from './../../../services/genral/tost.service';

import {
  Component,
  Input,
  Output,
  EventEmitter,
  OnInit,
  OnChanges,
  SimpleChanges,
  ViewChild,
  ElementRef,
  AfterViewInit,
  ChangeDetectorRef,
  inject,
  HostListener,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { NgClass } from '@angular/common';
import { TableModule } from 'primeng/table';
import { Subject, Subscription, debounceTime, distinctUntilChanged } from 'rxjs';

import {
  ColumnDefinition,
  DataTableConfig,
  SortConfig,
  FilterState,
  TableState,
  TableEvent,
} from '../../../models/datatable.model';
import { ComponentService } from '../../../services/genral/component.service';
import { Paginator } from 'primeng/paginator';
import { Modal } from '../modal/modal';
import { Filter } from '../filter/filter';
import { Loading } from '../loading/loading';
import { Error } from '../error/error';

import { Injectable } from '@angular/core';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable, { RowInput } from 'jspdf-autotable';

@Component({
  selector: 'app-datatable',
  templateUrl: './datatable.html',
  styleUrls: ['./datatable.css'],
  standalone: true,
  imports: [TableModule, FormsModule, NgClass, Paginator, Modal, Filter, Loading, Error],
})
export class Datatable implements OnInit, OnChanges, AfterViewInit {
  // ✅ API URL
  @Input() url!: string;
  @Input() name!: string;
  @Input() config: DataTableConfig = {
    columns: [],
  };
  @Input() tableName: string | null = null; // optional, used for parent-triggered revalidate

  filterModal: boolean = false;
  private readonly elRef = inject(ElementRef);
  loading: boolean = false;
  error: string | null = null;

  data: any[] = [];
  totalRecords: number = 0; // total records for pagination
  currentPage: number = 1;
  pageSize: number = 10;

  @Output() onRowClick = new EventEmitter<any>();
  @Output() onRowSelect = new EventEmitter<any[]>();
  @Output() onAdd = new EventEmitter<void>();
  @Output() onEdit = new EventEmitter<any>();
  @Output() onDelete = new EventEmitter<any>();
  @Output() onExport = new EventEmitter<'csv' | 'excel' | 'pdf'>();
  @Output() tableEvent = new EventEmitter<TableEvent>();
  @Input() tableSize = 'sm';

  @ViewChild('dt') dt!: ElementRef;

  internalState: TableState = {
    sort: null,
    filters: {},
    selection: { selectedRows: [], allSelected: false },
  };

  filterInputs: { [key: string]: any } = {};
  private filterSubject = new Subject<FilterState>();
  private toastService = inject(ToastService);

  currentSort: SortConfig | null = null;
  selectedRows: any[] = [];
  selectAll: boolean = false;
  visibleColumns: ColumnDefinition[] = [];
  showFilters: boolean = false;
  private cdr = inject(ChangeDetectorRef);
  private componentService = inject(ComponentService);
  private sub!: Subscription;
  exportOpen: boolean = false;

  // ================= LIFECYCLE =================

  ngOnInit() {
    this.initializeTable();

    this.filterSubject.pipe(debounceTime(400), distinctUntilChanged()).subscribe((filters) => {
      this.internalState.filters = filters;
      this.currentPage = 1; // reset to first page on filter change
      this.loadData();
    });

    if (this.url) {
      this.pageSize = 10;
      this.loadData();
    }

    // Listen for parent-triggered revalidation
    this.sub = this.componentService.revalidate$.subscribe((value) => {
      if (value && (value === this.tableName || value === '*')) {
        this.refresh(); // refresh already calls loadData and emits tableEvent
      }
    });
  }

  ngOnChanges(changes: SimpleChanges) {
    if (changes['config']) this.initializeTable();
    if (changes['url'] && this.url) this.loadData();
  }

  ngAfterViewInit() {
    this.cdr.detectChanges();
  }
  showMoreFilters() {
    this.showFilters = true;
  }
  closemodal() {
    this.showFilters = false;
  }

  // ================= CORE =================

  private initializeTable() {
    this.visibleColumns = this.config.columns
      .filter((c) => !c.hidden)
      .sort((a, b) => (a.order || 0) - (b.order || 0));

    if (this.config.sort) {
      this.internalState.sort = { ...this.config.sort };
      this.currentSort = this.config.sort;
    }

    if (this.config.filters) {
      this.internalState.filters = { ...this.config.filters };
      this.filterInputs = { ...this.config.filters };
    }

    this.pageSize = 10;
    this.clearSelection();
  }
  private exportToCsv(data: any[], filename: string): void {
    const csvContent = this.convertToCsv(data);
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.setAttribute('download', `${filename}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  // 2. Excel Export (Using SheetJS)
  private exportToExcel(data: any[], filename: string): void {
    const worksheet: XLSX.WorkSheet = XLSX.utils.json_to_sheet(data);
    const workbook: XLSX.WorkBook = { Sheets: { data: worksheet }, SheetNames: ['data'] };
    XLSX.writeFile(workbook, `${filename}.xlsx`);
  }

  private downloadFile(data: any[], filename: string, type: 'csv' | 'excel' | 'pdf'): void {
    switch (type) {
      case 'csv':
        this.exportToCsv(data, filename);
        break;
      case 'excel':
        this.exportToExcel(data, filename);
        break;
      case 'pdf':
        this.exportToPdf(data, filename);
        break;
    }
  }

  // 3. PDF Export (Using jsPDF)
  private exportToPdf(data: any[], filename: string): void {
    const doc = new jsPDF();

    // 2. Extract headers
    const head = [Object.keys(data[0])];

    // 3. Map values and cast explicitly to RowInput[]
    const body = data.map((item) => Object.values(item)) as RowInput[];

    autoTable(doc, {
      head: head,
      body: body,
    });

    doc.save(`${filename}.pdf`);
  }

  private convertToCsv(data: any[]): string {
    const headers = Object.keys(data[0]).join(',');
    const rows = data.map((row) => Object.values(row).join(','));
    return [headers, ...rows].join('\n');
  }

  private loadData() {
    if (!this.url) return;

    this.loading = true;
    this.error = null;

    const state = {
      page: this.currentPage || 1,
      pageSize: this.pageSize || 10,
      sortBy: this.internalState.sort?.column || null,
      sortDir: this.internalState.sort?.direction || null,
      filters: this.internalState.filters || {}, // always object
    };

    this.componentService.load(this.url, state).subscribe({
      next: (res: any) => {
        this.data = res.items || res.data || res.results || res.content || res || [];
        this.totalRecords = res.totalRecords || res.total || this.data.length;
        this.loading = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.error = err?.message ?? 'An unexpected error occurred';
        this.loading = false;
      },
    });
  }

  // ================= EVENTS =================

  refresh() {
    this.loadData();
    this.tableEvent.emit({ type: 'refresh', data: null });
    console.log('Data table refreshed', this.totalRecords);
  }
  toggleExport() {
    this.exportOpen = !this.exportOpen;
  }

  handleSort(event: any) {
    if (!this.url) return;

    const sortConfig: SortConfig = {
      column: event.field,
      direction: event.order === 1 ? 'asc' : 'desc',
    };

    this.internalState.sort = sortConfig;
    this.currentSort = sortConfig;
    this.loadData();
    this.tableEvent.emit({ type: 'sort', data: sortConfig });
  }

  handlePageChange(event: any) {
    // PrimeNG paginator emits first item index (0-based)
    this.currentPage = Math.floor(event.first / event.rows) + 1;
    this.pageSize = event.rows;

    console.log('Page Change Event:', event, ' -> currentPage:', this.currentPage);

    this.loadData();
  }

  handleFilter(key: string, value: any) {
    const newFilters = { ...this.filterInputs };

    if (!value) delete newFilters[key];
    else newFilters[key] = value;

    this.filterInputs = newFilters;
    this.filterSubject.next(newFilters);
  }

  handleRowClick(row: any) {
    this.onRowClick.emit(row);
    this.tableEvent.emit({ type: 'rowClick', data: row });
  }

  toggleRowSelection(row: any) {
    const idx = this.selectedRows.indexOf(row);

    if (idx > -1) {
      this.selectedRows.splice(idx, 1);
    } else {
      this.selectedRows.push(row);
    }

    // Update selectAll state
    this.selectAll = this.selectedRows.length === this.data.length && this.data.length > 0;

    this.internalState.selection.selectedRows = [...this.selectedRows];
    this.onRowSelect.emit([...this.selectedRows]);
  }

  handleSelectAll() {
    this.selectAll = !this.selectAll;

    this.selectedRows = this.selectAll ? [...this.data] : [];

    this.internalState.selection.selectedRows = [...this.selectedRows];
    this.onRowSelect.emit([...this.selectedRows]);
  }

  clearSelection() {
    this.selectedRows = [];
    this.selectAll = false;
    this.internalState.selection = { selectedRows: [], allSelected: false };
  }

  addNew() {
    if (this.config?.onAdd) {
      this.config.onAdd();
    }
    this.onAdd.emit();
    this.tableEvent.emit({ type: 'add', data: null });
  }

  handleEdit(row: any) {
    this.onEdit.emit(row);
    this.tableEvent.emit({ type: 'edit', data: row });
  }

  handleDelete(row: any) {
    this.onDelete.emit(row);
    this.tableEvent.emit({ type: 'delete', data: row });
  }
  private getVisibleData(): any[] {
    return this.data.map((row) => {
      const filteredRow: any = {};
      this.visibleColumns.forEach((col) => {
        filteredRow[col.label || col.key] = this.getCellValue(row, col);
      });
      return filteredRow;
    });
  }

  export(format: 'csv' | 'excel' | 'pdf') {
    this.onExport.emit(format);
    this.tableEvent.emit({ type: 'export', data: format });

    const dataToExport = this.getVisibleData(); // only visible columns
    this.downloadFile(dataToExport, this.tableName || 'export', format);
  }

  rowAction(row: any, action: any) {
    if (action.confirm) {
      this.toastService.confirmAction({ name: action.confirm.message }, () => action.action(row));
    } else {
      action.action(row);
    }
  }
  // ================= DISPLAY =================

  getCellValue(row: any, column: ColumnDefinition): any {
    const val = row[column.key];

    // 1️⃣ Use custom renderer if defined
    if (column.renderer) return column.renderer(val, row);

    // 2️⃣ Validation message if defined
    if (column.validation) {
      const validationResult = column.validation(val);
      if (validationResult) return validationResult;
    }

    // 3️⃣ Type-based formatting
    switch (column.type) {
      case 'date':
        return val ? new Date(val).toLocaleDateString() : '';
      case 'currency':
        return val !== undefined
          ? new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(val)
          : '';
      case 'boolean':
        return val ? 'Yes' : 'No';
      case 'number':
        return val !== undefined ? val : '';
      case 'select':
        // Show label from filterOptions if exists
        if (column.filterOptions && val !== undefined && val !== null) {
          const option = column.filterOptions.find((o) => o.value === val);
          return option ? option.label : val;
        }
        return val ?? '';
      case 'custom':
        return val ?? '';
      case 'action':
        return ''; // actions are handled in template
      default:
        return val ?? '';
    }
  }

  isColumnFilterable(column: ColumnDefinition): boolean {
    return !!column.filterType;
  }

  getFilterPlaceholder(column: ColumnDefinition): string {
    switch (column.filterType) {
      case 'text':
      case 'number':
        return `Enter ${column.label}`;
      case 'date':
        return `Select ${column.label}`;
      case 'boolean':
      case 'select':
      case 'multi-select':
        return `Select ${column.label}`;
      case 'range':
        return `Enter ${column.label} range`;
      default:
        return '';
    }
  }

  getRowClass(row: any): string {
    return this.selectedRows.includes(row) ? 'bg-blue-50' : '';
  }

  getColumnWidth(column: ColumnDefinition): string {
    return column.width || 'auto';
  }

  getCellClasses(column: ColumnDefinition): string {
    return column.cellClass || column.className || '';
  }

  getHeaderClasses(column: ColumnDefinition): string {
    let classes = 'px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider';
    if (column.sortable) classes += ' cursor-pointer';
    classes += ` ${column.headerClass || 'text-center'}`;
    return classes;
  }

  isRowSelected(row: any): boolean {
    return this.selectedRows.includes(row);
  }
  rowActionMenuOpen: { [key: string]: boolean } = {};

  toggleRowActions(row: any) {
    const key = row.id || row.key || JSON.stringify(row);

    // Close all other menus first
    Object.keys(this.rowActionMenuOpen).forEach((k) => {
      if (k !== key) this.rowActionMenuOpen[k] = false;
    });

    // Toggle current row menu
    this.rowActionMenuOpen[key] = !this.rowActionMenuOpen[key];
  }
  @HostListener('document:click', ['$event'])
  onDocumentClick(event: Event) {
    const target = event.target as HTMLElement;

    // --- Handle row action menus ---
    const insideRowMenu = target.closest('.row-action-container');
    if (!insideRowMenu) {
      this.closeAllRowActions(); // close any open row menus
      this.cdr.detectChanges(); // update UI
    }

    // --- Handle export dropdown ---
    const clickedInsideExport = this.elRef.nativeElement.contains(target);
    if (!clickedInsideExport) {
      this.exportOpen = false; // close export menu if clicked outside
    }
  }

  isRowActionsOpen(row: any) {
    const key = row.id || row.key || JSON.stringify(row);
    return !!this.rowActionMenuOpen[key];
  }

  closeAllRowActions() {
    this.rowActionMenuOpen = {};
  }
  applyFilters(filters: any) {
    this.internalState.filters = filters;
    console.log('Applying filters:', filters);
    this.currentPage = 1;
    this.showFilters = false;
    this.loadData();
  }
  ngOnDestroy() {
    if (this.sub) this.sub.unsubscribe();
  }
}
