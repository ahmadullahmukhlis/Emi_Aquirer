import { Component, inject, Input, OnInit } from '@angular/core';
import { IIndicatorChart } from '../../../../models/chart.model';
import { NgApexchartsModule } from 'ng-apexcharts';
import { ApiService } from '../../../../services/api/api.service';

@Component({
  selector: 'app-indicator-chart',
  standalone: true,
  imports: [NgApexchartsModule],
  templateUrl: './indicator-chart.html',
  styleUrl: './indicator-chart.css',
})
export class IndicatorChart implements OnInit {
  @Input() config!: IIndicatorChart;
  @Input() title: string = 'Performance Indicator';
  @Input() isServer: boolean = false;
  @Input() url?: string;
  @Input() height: number = 350;

  loading = false;
  error: any = null;

  private api = inject(ApiService);

  ngOnInit() {
    if (this.isServer && this.url) {
      this.loadData();
    }
  }

  loadData() {
    if (!this.url) return;

    this.loading = true;
    this.error = null;

    this.api.get(this.url).subscribe({
      next: (res: any) => {
        /**
         * Supported API formats:
         *
         * 1) { value: 75, label: "Success Rate" }
         * 2) { percentage: 75 }
         * 3) 75
         */

        const value = typeof res === 'number' ? res : (res?.value ?? res?.percentage ?? 0);

        const label = res?.label ?? this.config.label;

        this.config = {
          ...this.config,
          series: [Number(value)], // must be number
          label: label,
        };

        this.loading = false;
      },
      error: (err) => {
        this.error = err;
        this.loading = false;
      },
    });
  }
}
