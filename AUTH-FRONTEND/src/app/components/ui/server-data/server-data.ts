import {
  Component,
  Input,
  Output,
  EventEmitter,
  TemplateRef,
  ContentChild,
  OnInit,
  OnDestroy,
  inject,
  ChangeDetectorRef,
} from '@angular/core';
import { Subscription } from 'rxjs';
import { CommonModule } from '@angular/common';

import { ApiService } from '../../../services/api/api.service';
import { ComponentService } from '../../../services/genral/component.service';
import { Error } from '../error/error';

@Component({
  selector: 'app-server-data',
  standalone: true,
  imports: [CommonModule, Error],
  templateUrl: './server-data.html',
  styleUrls: ['./server-data.css'],
})
export class ServerData implements OnInit, OnDestroy {
  @Input() url: string = '';
  @Input() disableDefaultHeight: boolean = false;
  @Input() id: string | null = null;
  @Input() ignoreNull: boolean = false;
  @Input() fetchData: boolean = true;

  @Output() dataReceived = new EventEmitter<any>();

  @ContentChild(TemplateRef) template!: TemplateRef<any>;

  data: any = undefined;
  error: any = null;
  loading = false;
  renderKey = 0;

  private sub!: Subscription;
  private api = inject(ApiService);
  private componentService = inject(ComponentService);
  private cdr = inject(ChangeDetectorRef);

  ngOnInit() {
    // Initial fetch
    if (this.fetchData) {
      this.loadData();
    }

    // Listen for parent revalidation
    this.sub = this.componentService.revalidate$.subscribe((value) => {
      if (value && (value === this.id || value === '*')) {
        this.data = null; // Clear old data
        this.loading = true; // Trigger loading
        this.renderKey++; // Force template re-render
        this.loadData();
      }
    });
  }

  loadData() {
    if (!this.url) return;

    this.loading = true;
    this.error = null;

    this.api.get(this.url).subscribe({
      next: (res: any) => {
        // Normalize data (array or object)
        this.data = Array.isArray(res) ? res : (res?.data ?? res);

        this.loading = false;
        this.dataReceived.emit(this.data);

        // Force Angular to detect async changes
        this.cdr.detectChanges();
        console.log('Server component data:', this.data);
      },
      error: (err) => {
        this.error = err?.message ?? 'An unexpected error occurred';
        this.loading = false;
        this.cdr.detectChanges();
      },
    });
  }

  ngOnDestroy() {
    if (this.sub) this.sub.unsubscribe();
  }
}
