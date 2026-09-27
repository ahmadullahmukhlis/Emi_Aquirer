import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';

import { SidebarItem } from '../../../models/sidebar-item.model';
import { SidebarService } from '../../../services/sidebar.service';

import { ChangeDetectionStrategy } from '@angular/core';

@Component({
  selector: 'app-breadcrumb',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule, RouterModule],
  templateUrl: './breadcrumb.html',
  styleUrls: ['./breadcrumb.css'],
})
export class Breadcrumb {
  breadcrumb$ = signal<SidebarItem[]>([]);
  private sidebarService = inject(SidebarService);

  ngOnInit() {
    this.breadcrumb$.set(this.sidebarService.getBreadcrumb());
  }
}
