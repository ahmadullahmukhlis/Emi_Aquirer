import { Component, inject, Input, OnInit } from '@angular/core';
import { IAxisChart } from '../../../../models/chart.model';
import { NgApexchartsModule } from 'ng-apexcharts';
import { ApiService } from '../../../../services/api/api.service';

@Component({
  selector: 'app-linear-chart',
  standalone: true,
  imports: [NgApexchartsModule],
  templateUrl: './linear-chart.html',
  styleUrl: './linear-chart.css',
})
export class LinearChart implements OnInit {
  @Input() config!: IAxisChart;
  @Input() title: string = 'Linear Data';
  @Input() isServer: boolean = false;
  @Input() url?: string;
  @Input() height: number = 350;

  loading = false;
  data: any[] = [];
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
        this.data = Array.isArray(res) ? res : (res?.data ?? []);

        // IMPORTANT: Reassign config object (don't mutate)
        this.config = {
          ...this.config,
          categories: this.data.map((item: any) => item.name), // adjust as needed
          series: [
            {
              name: this.title,
              data: this.data.map((item: any) => item.value),
            },
          ],
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
