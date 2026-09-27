import { Component, Input, Output, EventEmitter } from '@angular/core';

@Component({
  selector: 'app-error',
  imports: [],
  templateUrl: './error.html',
  styleUrl: './error.css',
})
export class Error {
  @Input() error: string = 'Something went wrong!';

  /** Table size for padding variants: 'default' | 'sm' | 'xs' */
  @Input() size: 'default' | 'sm' | 'xs' = 'default';

  /** Event emitted when user clicks "Try Again" */
  @Output() refresh = new EventEmitter<void>();
}
