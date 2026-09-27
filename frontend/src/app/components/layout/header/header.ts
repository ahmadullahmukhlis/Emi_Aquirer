import {
  Component,
  ElementRef,
  inject,
  signal,
  computed,
  PLATFORM_ID,
  afterNextRender,
} from '@angular/core';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { SidebarService } from '../../../services/sidebar.service';
import { Breadcrumb } from '../breadcrumb/breadcrumb';
import { Router, NavigationEnd } from '@angular/router';
import { takeUntilDestroyed, toSignal } from '@angular/core/rxjs-interop';
import { filter, map } from 'rxjs/operators';
import { ComponentService } from '../../../services/genral/component.service';
import { AuthService } from '../../../services/auth.service';

@Component({
  selector: 'app-header',
  standalone: true,
  imports: [CommonModule, Breadcrumb],
  templateUrl: './header.html',
  styleUrls: ['./header.css'],
  // NEW: Consolidate global listeners here instead of using @HostListener
  host: {
    '(window:resize)': 'onResize()',
    '(document:click)': 'onDocumentClick($event)',
    '(document:keydown.escape)': 'onEsc()',
  },
})
export class Header {
  private readonly sidebarService = inject(SidebarService);
  private readonly elRef = inject(ElementRef);
  private readonly router = inject(Router);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  private readonly componentService = inject(ComponentService);
  readonly authService = inject(AuthService);

  // Use Signals for state management
  isNotificationsOpen = signal(false);
  isProfileMenuOpen = signal(false);
  isMobile = signal(false);

  notifications = signal([
    { id: 1, text: 'New user registered', time: '5 min ago', read: false, icon: 'fa-user-plus' },
    { id: 2, text: 'Server load is high', time: '15 min ago', read: false, icon: 'fa-server' },
    {
      id: 3,
      text: 'Report generated successfully',
      time: '1 hour ago',
      read: true,
      icon: 'fa-file-alt',
    },
    {
      id: 4,
      text: 'Database backup completed',
      time: '2 hours ago',
      read: true,
      icon: 'fa-database',
    },
  ]);

  unreadCount = computed(() => this.notifications().filter((n) => !n.read).length);
  isSidebarCollapsed = this.sidebarService.sidebarCollapsedSignal;

  constructor() {
    // NEW: afterNextRender is the modern, browser-safe replacement for ngAfterViewInit
    afterNextRender(() => {
      this.checkMobile();
    });

    // Handle router events reactively
    this.router.events
      .pipe(
        filter((event) => event instanceof NavigationEnd),
        takeUntilDestroyed(),
      )
      .subscribe(() => this.closeDropdowns());
  }

  onResize(): void {
    if (this.isBrowser) this.checkMobile();
  }

  private checkMobile(): void {
    this.isMobile.set(window.innerWidth < 768);
  }

  toggleNotifications(event?: MouseEvent): void {
    event?.stopPropagation();
    this.isNotificationsOpen.update((v) => !v);
    this.isProfileMenuOpen.set(false);
  }

  toggleProfileMenu(event?: MouseEvent): void {
    event?.stopPropagation();
    this.isProfileMenuOpen.update((v) => !v);
    this.isNotificationsOpen.set(false);
  }

  markAsRead(notificationId: number): void {
    this.notifications.update((list) =>
      list.map((n) => (n.id === notificationId ? { ...n, read: true } : n)),
    );
  }

  toggleSidebar(): void {
    this.sidebarService.toggleSidebar();
  }

  private closeDropdowns(): void {
    this.isNotificationsOpen.set(false);
    this.isProfileMenuOpen.set(false);
  }

  onDocumentClick(event: MouseEvent): void {
    if (this.isBrowser && !this.elRef.nativeElement.contains(event.target)) {
      this.closeDropdowns();
    }
  }

  onEsc(): void {
    this.closeDropdowns();
  }

  reloadData() {
    this.componentService.revalidate('*');
  }
  logout(){
    this.authService.logout();
  }
}
