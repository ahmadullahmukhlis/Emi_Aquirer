import {
  ApexAxisChartSeries,
  ApexNonAxisChartSeries,
  ApexXAxis,
  ApexPlotOptions,
} from 'ng-apexcharts';

/**
 * 1. AXIS INTERFACE
 * For: "line", "area", "bar", "scatter", "bubble", "heatmap", "radar", "treemap"
 */
export interface IAxisChart {
  type: 'line' | 'area' | 'bar' | 'scatter' | 'bubble' | 'heatmap' | 'radar' | 'treemap';
  series: ApexAxisChartSeries; // Format: [{ name: string, data: number[] }]
  categories: string[]; // Becomes xaxis.categories
}

/**
 * 2. PROPORTIONAL INTERFACE
 * For: "pie", "donut", "polarArea"
 */
export interface IProportionalChart {
  type: 'pie' | 'donut' | 'polarArea';
  series: ApexNonAxisChartSeries; // Format: [44, 55, 13, 33]
  labels: string[]; // Segment names
}

/**
 * 3. RANGE INTERFACE
 * For: "candlestick", "boxPlot", "rangeBar", "rangeArea"
 */
export interface IRangeChart {
  type: 'candlestick' | 'boxPlot' | 'rangeBar' | 'rangeArea';
  series: {
    name?: string;
    data: { x: any; y: number[] | [number, number] }[]; // Format: y: [val1, val2, ...]
  }[];
}

/**
 * 4. INDICATOR INTERFACE
 * For: "radialBar"
 */
export interface IIndicatorChart {
  type: 'radialBar';
  series: number[]; // Format: [70] (Percentage)
  label: string;
  plotOptions?: ApexPlotOptions; // For hollow, startAngle, endAngle
}
