import { Component, inject } from '@angular/core';
import { Modal } from '../../components/ui/modal/modal';
import { DynamicField } from '../../models/fomrBuilderModel';
import { DynamicFormBuilder } from '../../components/ui/dynamic-form-builder/dynamic-form-builder';
import { DataTableConfig, RowAction } from '../../models/datatable.model';
import { Datatable } from '../../components/ui/datatable/datatable';
import { ServerData } from '../../components/ui/server-data/server-data';
import { ComponentService } from '../../services/genral/component.service';
import { NgApexchartsModule } from 'ng-apexcharts';
import { MultipleRecord } from '../../components/ui/multiple-record/multiple-record';

@Component({
  selector: 'app-dashboard',
  imports: [Modal, DynamicFormBuilder, Datatable, ServerData, NgApexchartsModule],
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.css',
})
export class Dashboard {
  isOpent: boolean = false;
  private componentService = inject(ComponentService);
  openModal() {
    this.isOpent = true;
  }
  closeModal() {
    this.isOpent = false;
  }
  onSelectChange(enent: any) {
    console.log(enent);
  }
  recentActivities = [
    {
      title: 'New order received',
      description: 'Order #12345 from John Doe',
      time: '10 min ago',
      icon: 'fa-shopping-cart',
      bgColor: 'bg-blue-500',
      status: 'Completed',
      statusColor: 'bg-green-100 text-green-800',
    },
    {
      title: 'Database backup',
      description: 'Weekly backup completed successfully',
      time: '1 hour ago',
      icon: 'fa-database',
      bgColor: 'bg-green-500',
      status: 'Success',
      statusColor: 'bg-green-100 text-green-800',
    },
    {
      title: 'System alert',
      description: 'High CPU usage detected',
      time: '2 hours ago',
      icon: 'fa-exclamation-triangle',
      bgColor: 'bg-red-500',
      status: 'Warning',
      statusColor: 'bg-yellow-100 text-yellow-800',
    },
    {
      title: 'New user registration',
      description: 'Sarah Johnson joined the platform',
      time: '3 hours ago',
      icon: 'fa-user-plus',
      bgColor: 'bg-purple-500',
      status: 'Completed',
      statusColor: 'bg-green-100 text-green-800',
    },
    {
      title: 'Payment processed',
      description: 'Payment of $1,200 processed successfully',
      time: '5 hours ago',
      icon: 'fa-credit-card',
      bgColor: 'bg-indigo-500',
      status: 'Success',
      statusColor: 'bg-green-100 text-green-800',
    },
  ];

  stats = [
    {
      title: 'Total Revenue',
      value: '$42,580',
      change: '+12.5%',
      changeType: 'increase',
      icon: 'fa-dollar-sign',
      iconColor: 'text-green-600',
      bgColor: 'bg-green-100',
      period: 'From last month',
    },
    {
      title: 'Total Orders',
      value: '5,842',
      change: '+8.3%',
      changeType: 'increase',
      icon: 'fa-shopping-cart',
      iconColor: 'text-blue-600',
      bgColor: 'bg-blue-100',
      period: 'From last month',
    },
    {
      title: 'Active Users',
      value: '12,847',
      change: '-2.1%',
      changeType: 'decrease',
      icon: 'fa-users',
      iconColor: 'text-purple-600',
      bgColor: 'bg-purple-100',
      period: 'From last month',
    },
    {
      title: 'Conversion Rate',
      value: '3.24%',
      change: '+15.7%',
      changeType: 'increase',
      icon: 'fa-chart-line',
      iconColor: 'text-orange-600',
      bgColor: 'bg-orange-100',
      period: 'From last month',
    },
  ];

  topProducts = [
    { name: 'Premium Widget', sales: 1242, revenue: '$24,840', growth: '+12%' },
    { name: 'Basic Widget', sales: 856, revenue: '$8,560', growth: '+5%' },
    { name: 'Enterprise Widget', sales: 423, revenue: '$12,690', growth: '+23%' },
    { name: 'Starter Widget', sales: 321, revenue: '$3,210', growth: '-2%' },
    { name: 'Pro Widget', sales: 198, revenue: '$5,940', growth: '+18%' },
  ];

  getCurrentDate(): string {
    const date = new Date();
    return date.toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  }

  actionUrl = 'https://api.example.com/save';

  hiddenFields = [{ name: 'companyId', value: 5 }];

  beforeSubmit = (values: any) => {
    console.log('before submit', values);
    return true; // return false to stop submit
  };

  onSubmitCompleted(res: any) {
    console.log('submit completed:', res);
  }

  onValuesChanged(values: any) {
    console.log('form values changed:', values);
  }

  /* ===== YOUR FIELD ARRAY ===== */

  fields: DynamicField[] = [
    {
      type: 'profile-image',
      name: 'profileImage',
      label: '',
      disabled: false,
      className: 'col-span-2 mx-auto mb-4',
    },
    {
      type: 'text',
      name: 'title',
      label: 'User Information',

      defaultValue: 'kahn',
      disabled: true,
    },
    {
      type: 'text',
      name: 'firstName',
      label: 'First Name',

      required: true,
      disabled: false,
    },
    {
      type: 'text',
      name: 'lastName',
      label: 'Last Name',

      required: true,
      disabled: false,
    },
    {
      type: 'number',
      name: 'age',
      label: 'Age',
      disabled: false,
      max: 87,
    },
    {
      type: 'select',
      name: 'cityId',
      label: 'City',
      url: '/api/cities',
      changeValue: 'id',
      disabled: false,
      options: [
        {
          id: 1,
          name: 'ali',
        },
        {
          id: 2,
          name: 'khan',
        },
      ],
    },
    {
      type: 'file',
      name: 'avatar',
      label: 'Photo',
      disabled: false,
    },
    {
      type: 'server-select',
      name: 'post',
      label: 'posts',
      disabled: false,
      url: 'posts',
      optionLabel: 'title',
      optionValue: 'id',
    },
    {
      type: 'multi-select',
      name: 'multiPost',
      label: 'show test',
      disabled: false,
      url: 'posts',
      optionLabel: 'title',
      optionValue: 'id',
    },
    {
      type: 'file-upload',
      name: 'pt',
      label: 'show test',
      disabled: false,
      multiple: true,
      url: 'posts',
      optionLabel: 'title',
      optionValue: 'id',
      className: 'col-span-2',
    },
    {
      name: 'addresses',
      label: 'Addresses',
      type: 'repeater',
      disabled: false,
      className: 'col-span-2',
      defaultValue: [],
      form: {
        className: 'grid grid-cols-2 gap-4',
        fields: [
          {
            name: 'street',
            label: 'Street',
            type: 'text',
            required: true,
            disabled: false,
          },
          {
            name: 'city',
            label: 'City',
            type: 'text',
            required: true,
            disabled: false,
          },
        ],
      },
    },
  ];

  isLoading = false;
  errorMessage: string | null = null;
  actions: RowAction[] = [
    {
      label: 'View',
      icon: 'fa-eye',
      action: (row: any) => {
        console.log('View action on row:', row);
      },
      color: 'primary',
    },
    {
      label: 'Delete',
      icon: 'fa-trash',
      action: (row: any) => {
        console.log('Delete action on row:', row);
      },
      color: 'danger',
      confirm: {
        title: 'Confirm Deletion',
        message: 'Are you sure you want to delete this item?',
        confirmText: 'Yes, Delete',
        cancelText: 'Cancel',
      },
    },
  ];
  tableConfig: DataTableConfig = {
    columns: [
      { key: 'id', label: 'ID', sortable: true, width: '50px', className: 'font-bold text-center' },
      { key: 'name', label: 'full Name', sortable: true, filterType: 'text' },
      { key: 'username', label: 'User Name', sortable: true, filterType: 'text' },
      { key: 'email', label: 'Email', sortable: true, filterType: 'text' },
      { key: 'phone', label: 'Phone', sortable: true, type: 'text' },
      {
        key: 'website',
        label: 'Website',
        type: 'text',
        filterType: 'text',
        validation: (value: any) => {
          return value == 'demarco.info' ? '<p class="text-red-500">' + value + '</p>' : value;
        },
      },
    ],

    showCheckboxes: true,
    selectable: true,
    rowActions: this.actions,
    rowClass: (row: any) => 'bg-gray-50',
    filters: this.fields,
  };

  // ================= EVENT HANDLERS =================

  handleRowClick(row: any) {
    console.log('Row clicked:', row);
  }

  handleRowSelect(rows: any[]) {
    console.log('Rows selected:', rows);
  }

  handleAdd() {
    console.log('Add new row');
  }

  handleEdit(row: any) {
    console.log('Edit row:', row);
  }

  handleDelete(row: any) {
    console.log('Delete row:', row);
  }

  handleExport(format: 'csv' | 'excel' | 'pdf') {
    console.log('Export table as:', format);
  }

  handleTableEvent(event: any) {
    console.log('Table event:', event);
  }
  reloadData() {
    this.componentService.revalidate('users-table');
  }
}
