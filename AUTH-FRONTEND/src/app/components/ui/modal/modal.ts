import { Component, EventEmitter, Input, Output } from '@angular/core';
import { DialogModule } from 'primeng/dialog';

@Component({
  selector: 'app-modal',
  standalone: true,
  imports: [DialogModule],
  templateUrl: './modal.html',
})
export class Modal{

  @Input() visible: boolean = false;
  @Input() draggable :boolean = true
  @Input() title: string = 'Modal Title';

  // Tailwind or custom classes
  @Input() widthClass: string = 'w-[500px]';
  @Input() heightClass: string = 'auto';

  // Event fired when X is clicked
  @Output() onClose = new EventEmitter<void>();

  // Do NOT change visible here! just emit event
  closeClicked() {
    this.onClose.emit();
  }
}
