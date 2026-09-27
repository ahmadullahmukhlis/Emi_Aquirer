import { Component, inject } from '@angular/core';
import { Datatable } from '../../../components/ui/datatable/datatable';
import { DataTableConfig, RowAction } from '../../../models/datatable.model';
import { ComponentService } from '../../../services/genral/component.service';
import { Modal } from "../../../components/ui/modal/modal";
import { DynamicField } from '../../../models/fomrBuilderModel';
import { DynamicFormBuilder } from "../../../components/ui/dynamic-form-builder/dynamic-form-builder";
import { ApiService } from '../../../services/api/api.service';
import e from 'express';

@Component({
  selector: 'app-client',
  imports: [Datatable, Modal, DynamicFormBuilder],
  templateUrl: './client.html',
  styleUrl: './client.css',
})
export class Client {
  private componentService = inject(ComponentService)
  private readonly api = inject(ApiService);
  addCLient :  boolean = false;
     actions: RowAction[] = [
        {
          label: 'Edit',
          icon: 'fa-edit',
          action: (row: any) => {
            this.delete(row.id)
          },
          color: 'warning',
        },
        {
          label: 'Delete',
          icon: 'fa-trash',
          action: (row: any) => {
             this.delete(row.id)

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

    tableConfig: DataTableConfig= {
      columns: [
        { key: 'id', label: 'ID', sortable: true, width: '50px', className: 'font-bold text-center' },
        { key: 'name', label: 'full Name', sortable: true, filterType: 'text' },
        { key: 'publicKey', label: 'Public Key', sortable: false, filterType: 'text' },
        { key: 'privateKey', label: 'Private Key', sortable: false, filterType: 'text' },
   
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
      
      onAdd : ()=>{
        this.addCLient = true;
      },
      rowActions:this.actions
    
    };
    handleRowClick(row: any) {
    console.log('Row clicked:', row);
  }
    fields: DynamicField[] = [
      {
        type: 'text',
        name: 'name',
        label: 'Client Name',
        disabled: false,
        className: 'col-span-2',
        placeholder:"client name"
      },
   
    
    ]
   
  handleClose(){
    this.addCLient= false;
  }
  handleSubmit(){
    this.handleClose()
    this.componentService.revalidate('CLients-table');

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
  delete(id:any){
      this.componentService.delete(`client/${id}`, {
         onSuccess: (e:any) => {
          this.componentService.revalidate('CLients-table');
          this.handleClose()
        },
         onError: (err) => {
           console.error('Delete failed:', err);
         },
       });
  }
}
