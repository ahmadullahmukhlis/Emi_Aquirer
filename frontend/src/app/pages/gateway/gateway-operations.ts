import { CommonModule } from '@angular/common';
import { Component, Input, OnInit, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../services/api/api.service';

type Transaction = { transactionId: string; channel: string; operation: string; merchantId: string; terminalId?: string; amountMinor?: number; currency: string; status: string; responseCode: string; stan: string; rrn?: string; createdAt: string };
type Terminal = { id: string; terminalId: string; merchantId: string; serialNumber: string; model: string; status: string };

@Component({ selector: 'app-gateway-operations', standalone: true, imports: [CommonModule, FormsModule], templateUrl: './gateway-operations.html', styleUrl: './gateway-operations.css' })
export class GatewayOperations implements OnInit {
  @Input() section = 'transactions';
  private api = inject(ApiService);
  transactions: Transaction[] = []; terminals: Terminal[] = []; merchants: any[] = []; settlements: any[] = []; settlementAccounts: any[] = []; auditEvents: any[] = [];
  workspaces: any[] = []; workspaceApps: any[] = []; workspaceMembers: any[] = []; selectedWorkspaceId = ''; newWorkspaceName = ''; newAppName = ''; inviteSubject = ''; inviteRole = 'DEVELOPER';
  error = ''; notice = ''; operation = 'PURCHASE'; channel = 'POS'; merchantId = ''; terminalId = ''; amountMinor: number | null = null; cardToken = ''; originalTransactionId = '';
  environment: 'TEST' | 'PRODUCTION' = 'TEST';
  simulatorScenario = 'APPROVED';
  pendingRequestId = '';
  readonly simulatorScenarios = ['APPROVED', 'DECLINED', 'TIMEOUT', 'DUPLICATE', 'SWITCH_UNAVAILABLE', 'MALFORMED_RESPONSE'];
  readonly operations = ['BALANCE_INQUIRY', 'PURCHASE', 'CASH_IN', 'CASH_OUT', 'PAYMENT_INFO', 'SAVE_PAYMENT', 'WALLET_TO_CARD', 'CARD_TO_WALLET', 'CARD_TO_CARD', 'CARD_TITLE_FETCH', 'CROSS_CURRENCY', 'REVERSAL'];
  ngOnInit() { this.refresh(); this.loadWorkspaces(); }
  loadWorkspaces() { this.api.get<any[]>('/api/v1/portal/workspaces').subscribe({ next: rows => { this.workspaces = rows ?? []; if (!this.selectedWorkspaceId && this.workspaces.length) { this.selectedWorkspaceId = this.workspaces[0].id; this.loadWorkspaceApps(); } }, error: e => this.fail(e) }); }
  loadWorkspaceApps() { if (!this.selectedWorkspaceId) { this.workspaceApps = []; this.workspaceMembers = []; return; } this.api.get<any[]>(`/api/v1/portal/workspaces/${this.selectedWorkspaceId}/apps`).subscribe({ next: rows => this.workspaceApps = rows ?? [], error: e => this.fail(e) }); this.api.get<any[]>(`/api/v1/portal/workspaces/${this.selectedWorkspaceId}/members`).subscribe({ next: rows => this.workspaceMembers = rows ?? [], error: e => this.fail(e) }); }
  createWorkspace() { const name = this.newWorkspaceName.trim(); if (!name) return; this.api.post<any>('/api/v1/portal/workspaces', { name }).subscribe({ next: workspace => { this.newWorkspaceName = ''; this.selectedWorkspaceId = workspace.id; this.loadWorkspaces(); }, error: e => this.fail(e) }); }
  createWorkspaceApp() { const name = this.newAppName.trim(); if (!name || !this.selectedWorkspaceId) return; this.api.post<any>(`/api/v1/portal/workspaces/${this.selectedWorkspaceId}/apps`, { name }).subscribe({ next: () => { this.newAppName = ''; this.loadWorkspaceApps(); }, error: e => this.fail(e) }); }
  inviteMember() { const subject = this.inviteSubject.trim(); if (!subject || !this.selectedWorkspaceId) return; this.api.post<any>(`/api/v1/portal/workspaces/${this.selectedWorkspaceId}/invites`, { subject, role: this.inviteRole }).subscribe({ next: () => { this.inviteSubject = ''; this.notice = 'Workspace invitation created. The invited user must accept it after signing in.'; this.loadWorkspaceApps(); }, error: e => this.fail(e) }); }
  refresh() {
    this.error = '';
    this.api.get<any>('/api/v1/admin/overview').subscribe({ next: v => { this.merchants = v.merchants ?? []; this.terminals = v.terminals ?? []; this.settlementAccounts = v.settlementAccounts ?? []; this.auditEvents = v.auditEvents ?? []; }, error: e => this.fail(e) });
    this.api.get<Transaction[]>('/api/v1/admin/transactions').subscribe({ next: v => this.transactions = v ?? [], error: e => this.fail(e) });
    this.api.get<any[]>('/api/v1/admin/settlements').subscribe({ next: v => this.settlements = v ?? [], error: e => this.fail(e) });
  }
  submit() {
    if (!this.merchantId || (this.channel === 'POS' && !this.terminalId)) { this.error = 'Merchant ID and, for POS, terminal ID are required.'; return; }
    const information = ['BALANCE_INQUIRY', 'PAYMENT_INFO', 'CARD_TITLE_FETCH'].includes(this.operation);
    if (!information && (!this.amountMinor || this.amountMinor <= 0)) { this.error = 'A positive amount is required.'; return; }
    const id = crypto.randomUUID(); const body = { requestId: id, idempotencyKey: `portal-${id}`, merchantId: this.merchantId, terminalId: this.channel === 'POS' ? this.terminalId : undefined, amountMinor: information ? undefined : this.amountMinor, currency: 'AFN', cardToken: this.cardToken || undefined, originalTransactionId: this.originalTransactionId || undefined };
    const submit = () => this.api.post(`/api/v1/${this.channel.toLowerCase()}/transactions/${this.operation}`, body).subscribe({ next: () => { this.notice = `${this.environment} request accepted. Do not submit another request if the transaction becomes pending.`; this.refresh(); }, error: e => this.fail(e) });
    if (this.environment === 'TEST') {
      this.pendingRequestId = id;
      this.api.post('/api/v1/admin/aps-simulator', { transactionId: id, scenario: this.simulatorScenario }).subscribe({ next: submit, error: e => this.fail(e) });
    } else submit();
  }
  money(value?: number, currency = 'AFN') { return `${currency} ${((value ?? 0) / 100).toFixed(2)}`; }
  private fail(e: any) { this.error = e?.error?.message || 'Gateway data is unavailable.'; }
}
