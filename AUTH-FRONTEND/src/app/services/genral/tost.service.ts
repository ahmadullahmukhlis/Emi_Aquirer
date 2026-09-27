import { Injectable } from '@angular/core';
import { ConfirmationService, MessageService } from 'primeng/api';

interface ConfirmItem {
  name?: string | null;
  model?: string | null;
}

type ConfirmCallback = () => void;


@Injectable({
  providedIn: 'root'
})
export class ToastService {

  constructor(private messageService: MessageService, private confirm: ConfirmationService) { }

  success(summary: string = 'Success', detail: string = 'Record saved successfully', life = 3000) {
    this.messageService.add({ severity: 'success', summary, detail, life });
  }



  error(error = '', summary: string = 'Error', detail: string = "An error occurred and we couldn't save your data. Please try again later", life = 4000) {
    this.messageService.add({ severity: 'error', summary, detail: detail + '\n' + error, life });
  }

  deleteError(error = '', summary: string = 'Error', detail: string = "An error occurred and we couldn't delete your data. Please try again later", life = 4000) {
    this.messageService.add({ severity: 'error', summary, detail: detail ? detail + '\n' + error : error, life });
  }

  info(summary: string, detail: string, life = 3000) {
    this.messageService.add({ severity: 'info', summary, detail, life });
  }

  deletionInfo(life = 3000) {
    this.messageService.add({ severity: 'info', summary: 'Deleted', detail: 'Item Deleted successfully', life });
  }

  warn(summary: string, detail: string, life = 3000) {
    this.messageService.add({ severity: 'warn', summary, detail, life });
  }

  dataLoadingError(error = '', summary: string = 'Error', detail: string = "Sorry, An error occurred while loading table data. Please, refresh the page", life = 4000) {
    this.messageService.add({ severity: 'error', summary, detail: detail + '\n' + error, life });
  }



  clear() {
    this.messageService.clear();
  }

  confirmAction(
      item: ConfirmItem = {},
      onAccept: ConfirmCallback,
      options?: {
        message?: string,
        icon?: string,
        actionLabel?: string,
        onReject?: ConfirmCallback
      }
  ) {
    const name = item.name || 'this item';
    const model = item.model ? ' ' + item.model : '';
    const actionLabel = options?.actionLabel || 'Confirm';
    const icon = options?.icon || 'pi pi-exclamation-triangle';
    const message = options?.message || `Are you sure you want to ${actionLabel.toLowerCase()} ${name}${model}?`;

    this.confirm.confirm({
      key: 'confirm-action',
      header: actionLabel,
      message,
      icon,
      acceptLabel: 'Yes',
      rejectLabel: 'No',
      acceptButtonStyleClass: actionLabel === 'Delete' ? 'p-button-danger' : 'p-button-primary',
      rejectButtonStyleClass: 'p-button-secondary',
      accept: () => onAccept(),
      reject: () => {
        if (options?.onReject) {
          options.onReject();
        } else {
          this.warn('Canceled', `${actionLabel} was cancelled`);
        }
      }
    });
  }



  confirmDelete(
      item: ConfirmItem = {},
      onAccept: ConfirmCallback
  ) {
    this.confirmAction(item, onAccept, {
      actionLabel: 'Delete',
      icon: 'pi pi-trash'
    });
  }

  confirmOption(
      item: ConfirmItem = {},
      onAccept: ConfirmCallback,
      options?: {
        message?: string,
        icon?: string,
        actionLabel?: string,
        onReject?: ConfirmCallback
      }
  ) {
    this.confirmAction(item, onAccept, options);
  }
}
