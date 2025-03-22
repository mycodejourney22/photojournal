// app/javascript/controllers/chart_controller.js

import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"
Chart.register(...registerables);

export default class extends Controller {
  static values = {
    type: String,
    labels: Array,
    datasets: Array,
    options: Object
  }

  connect() {
    this.initializeChart();
  }

  initializeChart() {
    const canvas = this.element;
    const ctx = canvas.getContext("2d");

    // Try to parse chart data from dataset
    let chartData = {};
    try {
      if (this.element.dataset.chartData) {
        chartData = JSON.parse(this.element.dataset.chartData);
      }
    } catch (e) {
      console.error("Error parsing chart data:", e);
    }

    // Determine chart type
    let chartType = 'bar';
    if (this.element.id.includes('Pie') || this.element.id.includes('Doughnut')) {
      chartType = 'pie';
    } else if (this.element.id.includes('Line')) {
      chartType = 'line';
    }

    // Configure chart based on ID or parsed data
    if (this.element.id === 'customerAcquisitionChart') {
      this.createCustomerAcquisitionChart(ctx, chartData);
    } else if (this.element.id === 'revenueByCustomerTypeChart') {
      this.createRevenueByCustomerTypeChart(ctx, chartData);
    } else if (this.element.id === 'customerRetentionChart') {
      this.createCustomerRetentionChart(ctx, chartData);
    } else if (this.element.id === 'salesByCategoryChart') {
      this.createSalesByCategoryChart(ctx, chartData);
    } else if (this.element.id === 'salesByLocationChart') {
      this.createSalesByLocationChart(ctx, chartData);
    } else if (chartData.labels && chartData.datasets) {
      // Generic chart creation if data structure is complete
      this.createGenericChart(ctx, chartType, chartData);
    }
  }

  createCustomerAcquisitionChart(ctx, data) {
    const labels = data.map(item => item.month);
    const values = data.map(item => item.count);

    new Chart(ctx, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: [{
          label: 'New Customers',
          data: values,
          backgroundColor: '#EDD400',
          borderWidth: 0
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              precision: 0
            }
          }
        },
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                return `${context.raw} new customers`;
              }
            }
          }
        }
      }
    });
  }

  createRevenueByCustomerTypeChart(ctx, data) {
    const labels = data.map(item => item.label);
    const values = data.map(item => item.value);

    new Chart(ctx, {
      type: 'pie',
      data: {
        labels: labels,
        datasets: [{
          data: values,
          backgroundColor: ['#4285F4', '#EDD400'],
          borderWidth: 0
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom'
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                let label = context.label || '';
                if (label) {
                  label += ': ';
                }
                const value = context.raw;
                label += '₦' + value.toLocaleString();

                // Add percentage
                const total = values.reduce((a, b) => a + b, 0);
                const percentage = ((value / total) * 100).toFixed(1);
                label += ` (${percentage}%)`;

                return label;
              }
            }
          }
        }
      }
    });
  }

  createCustomerRetentionChart(ctx, data) {
    const labels = data.map(item => item.month);
    const retentionValues = data.map(item => item.retention);

    new Chart(ctx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [{
          label: 'Retention Rate (%)',
          data: retentionValues,
          borderColor: '#4285F4',
          backgroundColor: 'rgba(66, 133, 244, 0.1)',
          fill: true,
          tension: 0.3,
          borderWidth: 2
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            max: 100,
            ticks: {
              callback: function(value) {
                return value + '%';
              }
            }
          }
        },
        plugins: {
          tooltip: {
            callbacks: {
              label: function(context) {
                return `Retention: ${context.raw}%`;
              }
            }
          }
        }
      }
    });
  }

  createSalesByCategoryChart(ctx, data) {
    const labels = data.map(item => item.category);
    const values = data.map(item => item.amount);

    new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: labels,
        datasets: [{
          data: values,
          backgroundColor: [
            '#4285F4', '#EDD400', '#0F9D58', '#DB4437',
            '#9C27B0', '#FF9800', '#00BCD4', '#795548'
          ],
          borderWidth: 0
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'right'
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                let label = context.label || '';
                if (label) {
                  label += ': ';
                }
                const value = context.raw;
                label += '₦' + value.toLocaleString();
                return label;
              }
            }
          }
        }
      }
    });
  }

  createSalesByLocationChart(ctx, data) {
    const labels = data.map(item => item.location);
    const values = data.map(item => item.amount);

    new Chart(ctx, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: [{
          label: 'Revenue',
          data: values,
          backgroundColor: [
            '#4285F4', '#EDD400', '#0F9D58'
          ],
          borderWidth: 0
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              callback: function(value) {
                if (value >= 1000000) {
                  return '₦' + (value / 1000000).toFixed(1) + 'M';
                } else if (value >= 1000) {
                  return '₦' + (value / 1000).toFixed(0) + 'k';
                }
                return '₦' + value;
              }
            }
          }
        },
        plugins: {
          tooltip: {
            callbacks: {
              label: function(context) {
                return '₦' + context.raw.toLocaleString();
              }
            }
          }
        }
      }
    });
  }

  createGenericChart(ctx, type, data) {
    new Chart(ctx, {
      type: type,
      data: {
        labels: data.labels,
        datasets: data.datasets
      },
      options: data.options || {
        responsive: true,
        maintainAspectRatio: false
      }
    });
  }
}
