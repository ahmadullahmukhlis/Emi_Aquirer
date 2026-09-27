import { Component } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { GatewayOperations } from './gateway-operations';

@Component({
  selector: 'app-gateway-section',
  standalone: true,
  imports: [GatewayOperations],
  template: '<app-gateway-operations [section]="section" />',
})
export class GatewaySection {
  readonly section: string;

  constructor(route: ActivatedRoute) {
    this.section = route.snapshot.data['section'] ?? 'transactions';
  }
}
