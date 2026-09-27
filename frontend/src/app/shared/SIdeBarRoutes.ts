import { SidebarItem } from '../models/sidebar-item.model';

export const SIDEBAR_ROUTES: SidebarItem[] = [
  {
    id: 2,
    label: 'Access & Identity',
    icon: 'fa-user-shield',
    route: '/auth',
    isActive: false,
    isExpanded: false,
    children: [
      { id: 42, label: 'Users', icon: 'fa-users', route: '/auth/users', isActive: false },
      { id: 44, label: 'Roles', icon: 'fa-user-tag', route: '/auth/roles', isActive: false },
      { id: 46, label: 'Permissions', icon: 'fa-shield-alt', route: '/auth/permissions', isActive: false },
      { id: 48, label: 'MFA & Email', icon: 'fa-lock', route: '/auth/mfa', isActive: false },
    ],
  },
  {
    id: 5,
    label: 'Payment Gateway',
    icon: 'fa-solid fa-credit-card',
    route: '/gateway',
    isActive: false,
    isExpanded: false,
    children: [
      { id: 52, label: 'Acquiring', icon: 'fa-building-columns', route: '/gateway/acquiring', isActive: false, isExpanded: false, children: [
        { id: 522, label: 'Merchants & Outlets', icon: 'fa-store', route: '/gateway/acquiring/merchants', isActive: false },
        { id: 523, label: 'Terminals', icon: 'fa-cash-register', route: '/gateway/acquiring/terminals', isActive: false },
      ] },
      { id: 53, label: 'Transactions', icon: 'fa-arrow-right-arrow-left', route: '/gateway/transactions', isActive: false, isExpanded: false, children: [
        { id: 531, label: 'Transaction Monitor', icon: 'fa-list', route: '/gateway/transactions/monitor', isActive: false },
        { id: 532, label: 'Transaction Details', icon: 'fa-circle-info', route: '/gateway/transactions/details', isActive: false },
      ] },
      { id: 54, label: 'Fees & Settlement', icon: 'fa-money-bill-transfer', route: '/gateway/settlements', isActive: false, isExpanded: false, children: [
        { id: 541, label: 'Settlement Batches', icon: 'fa-calendar-check', route: '/gateway/settlements/batches', isActive: false },
        { id: 542, label: 'Reconciliation', icon: 'fa-scale-balanced', route: '/gateway/settlements/reconciliation', isActive: false },
      ] },
      { id: 56, label: 'Operations', icon: 'fa-list-check', route: '/gateway/operations', isActive: false, isExpanded: false, children: [
        { id: 561, label: 'Reminders', icon: 'fa-bell', route: '/gateway/operations/reminders', isActive: false },
        { id: 562, label: 'Audit Trail', icon: 'fa-clock-rotate-left', route: '/gateway/operations/audit', isActive: false },
      ] },
      { id: 57, label: 'Integrations', icon: 'fa-plug', route: '/gateway/integrations', isActive: false, isExpanded: false, children: [
        { id: 571, label: 'Partners', icon: 'fa-code-branch', route: '/gateway/integrations/partners', isActive: false },
        { id: 572, label: 'Payment Intents', icon: 'fa-mobile-screen', route: '/gateway/integrations/intents', isActive: false },
      ] },
      { id: 59, label: 'Platform', icon: 'fa-users', route: '/gateway/platform', isActive: false, isExpanded: false, children: [
        { id: 591, label: 'KYC Review', icon: 'fa-user-check', route: '/gateway/platform/kyc', isActive: false },
        { id: 592, label: 'Webhooks', icon: 'fa-link', route: '/gateway/platform/webhooks', isActive: false },
      ] },
      { id: 60, label: 'ISO Profiles', icon: 'fa-code', route: '/gateway/iso', isActive: false, isExpanded: false, children: [
        { id: 601, label: 'Profiles', icon: 'fa-file-code', route: '/gateway/iso/profiles', isActive: false },
        { id: 602, label: 'Field Rules', icon: 'fa-list-ol', route: '/gateway/iso/fields', isActive: false },
      ] },
    ],
  },
];
