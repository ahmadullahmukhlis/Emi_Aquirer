import {
  Component,
  OnInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  inject,
} from '@angular/core';
import { trigger, transition, style, animate } from '@angular/animations';
import { SidebarService } from '../../../services/sidebar.service';
import { SidebarItem } from '../../../models/sidebar-item.model';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { AuthService } from '../../../services/auth.service';

@Component({
  selector: 'app-sidebar',
  templateUrl: './sidebar.html',
  styleUrls: ['./sidebar.css'],
  standalone: true,
  imports: [CommonModule, RouterModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  animations: [
    trigger('childAnimation', [
      transition(':enter', [
        style({ height: 0, opacity: 0, overflow: 'hidden' }),
        animate('200ms ease-out', style({ height: '*', opacity: 1 })),
      ]),
      transition(':leave', [
        style({ overflow: 'hidden' }),
        animate('150ms ease-in', style({ height: 0, opacity: 0 })),
      ]),
    ]),
  ],
})
export class Sidebar implements OnInit {
  readonly authService = inject(AuthService);
  sidebarItems: SidebarItem[] = [];
  isCollapsed = false;

  constructor(
    private sidebarService: SidebarService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.sidebarItems = this.sidebarService.getSidebarItems();
    this.isCollapsed = this.sidebarService.isCollapsed();
    this.cdr.markForCheck();
  }

  toggleItemExpansion(itemId: number): void {
    this.sidebarService.toggleItemExpansion(itemId);
    this.cdr.markForCheck();
  }

  setActiveItem(itemId: number): void {
    this.sidebarService.setActiveItem(itemId);
    this.cdr.markForCheck();
  }

  toggleSidebar(): void {
    this.sidebarService.toggleSidebar();
    this.isCollapsed = this.sidebarService.isCollapsed();
    this.cdr.markForCheck();
  }

  trackById(index: number, item: SidebarItem): number {
    return item.id;
  }
}
