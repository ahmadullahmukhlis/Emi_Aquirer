import { CommonModule } from '@angular/common';
import { Component, HostListener } from '@angular/core';
import { RouterModule } from '@angular/router';
import { Sidebar } from '../sidebar/sidebar';
import { Header } from '../header/header';
import { SidebarService } from '../../../services/sidebar.service';
import { DeleteConfirmation } from '../../ui/delete-confirmation/delete-confirmation';
import { ToastComponent } from '../../ui/toast.component/toast.component';

@Component({
  selector: 'app-main-content',
  standalone: true,
  imports: [CommonModule, RouterModule, Sidebar, Header, DeleteConfirmation, ToastComponent],
  templateUrl: './main-content.html',
  styleUrls: ['./main-content.css'],
})
export class MainContent {
  isMobile = false;

  constructor(private sidebarService: SidebarService) {
    this.checkMobile();
  }

  @HostListener('window:resize')
  onResize(): void {
    this.checkMobile();
  }

  private checkMobile(): void {
    this.isMobile = window.innerWidth < 768;
  }

  // Getter for collapsed sidebar state (no arguments needed)
  get isCollapsed(): boolean {
    return this.sidebarService.isCollapsed();
  }
}
