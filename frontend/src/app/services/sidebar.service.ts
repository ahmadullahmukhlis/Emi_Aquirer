import { Injectable, signal, effect } from '@angular/core';
import { SidebarItem } from '../models/sidebar-item.model';
import { SIDEBAR_ROUTES } from '../shared/SIdeBarRoutes';

@Injectable({
  providedIn: 'root',
})
export class SidebarService {
  private sidebarItems: SidebarItem[] = structuredClone(SIDEBAR_ROUTES);

  private readonly STORAGE_KEY = 'sidebar-collapsed';

  // ✅ Initialize from localStorage
  private _isCollapsed = signal<boolean>(localStorage.getItem(this.STORAGE_KEY) === 'true');

  // Expose signal
  sidebarCollapsedSignal = this._isCollapsed;

  constructor() {
    // ✅ Persist automatically whenever value changes
    effect(() => {
      localStorage.setItem(this.STORAGE_KEY, this._isCollapsed().toString());
    });
  }

  // ---------------- Breadcrumb Logic ----------------

  getBreadcrumb(): SidebarItem[] {
    const path: SidebarItem[] = [];

    const traverse = (items: SidebarItem[]): boolean => {
      for (const item of items) {
        // If this item is active, add to path
        if (item.isActive) {
          path.push(item);

          // If children exist, keep digging
          if (item.children?.length) {
            const foundChild = traverse(item.children);
            if (foundChild) {
              return true;
            }
          }
          return true;
        }

        // If not active but has children, search deeper
        if (item.children?.length) {
          const foundChild = traverse(item.children);
          if (foundChild) {
            path.unshift(item); // add parent before child
            return true;
          }
        }
      }
      return false;
    };

    traverse(this.sidebarItems);
    return path;
  }

  // ---------------- Sidebar Items ----------------

  getSidebarItems(): SidebarItem[] {
    return this.sidebarItems;
  }

  toggleItemExpansion(itemId: number): void {
    if (this._isCollapsed()) return; // prevent expanding when collapsed

    const item = this.findItemById(this.sidebarItems, itemId);
    if (item && item.children) {
      item.isExpanded = !item.isExpanded;
    }
  }

  setActiveItem(itemId: number): void {
    this.deactivateAllItems(this.sidebarItems);
    const item = this.findItemById(this.sidebarItems, itemId);
    if (item) item.isActive = true;
  }

  // ---------------- Sidebar Collapse ----------------

  toggleSidebar(): void {
    this._isCollapsed.set(!this._isCollapsed());

    if (this._isCollapsed()) {
      this.collapseAllItems(this.sidebarItems);
    }
  }

  isCollapsed(): boolean {
    return this._isCollapsed();
  }

  // ---------------- Private Helpers ----------------

  private deactivateAllItems(items: SidebarItem[]): void {
    items.forEach((item) => {
      item.isActive = false;
      if (item.children) {
        this.deactivateAllItems(item.children);
      }
    });
  }

  private collapseAllItems(items: SidebarItem[]): void {
    items.forEach((item) => {
      if (item.children) {
        item.isExpanded = false;
        this.collapseAllItems(item.children);
      }
    });
  }

  private findItemById(items: SidebarItem[], id: number): SidebarItem | null {
    for (const item of items) {
      if (item.id === id) return item;

      if (item.children) {
        const found = this.findItemById(item.children, id);
        if (found) return found;
      }
    }
    return null;
  }
}
