import { Component } from '@angular/core';
import { Button } from 'primeng/button';
import { ConfirmDialog } from 'primeng/confirmdialog';

@Component({
  selector: 'app-delete-confirmation',
  imports: [Button, ConfirmDialog],
  templateUrl: './delete-confirmation.html',
  styleUrl: './delete-confirmation.css',
})
export class DeleteConfirmation {

}
