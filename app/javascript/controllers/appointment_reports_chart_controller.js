// app/javascript/controllers/appointment_reports_chart_controller.js
import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables);

export default class extends Controller {
  static targets = [
    "appointmentsChart",
    "appointmentsByDateChart",
    "photoshootsChart",
    "missedChart",
    "onlineBookingsChart",
    "cancelledBookingsChart",    // NEW TARGET
    "walkInBookingsChart",       // NEW TARGET
    "locationChart",
    "shootTypesChart"
  ]

  connect() {
    this.initializeCharts();
  }

  disconnect() {
    // Clean up charts when controller disconnects
    if (this.charts) {
      this.charts.forEach(chart => chart.destroy());
    }
  }

  initializeCharts() {
    this.charts = [];

    // Initialize each chart
    if (this.hasAppointmentsChartTarget) {
      this.charts.push(this.createAppointmentsChart());
    }

    if (this.hasAppointmentsByDateChartTarget) {
      this.charts.push(this.createAppointmentsByDateChart());
    }

    if (this.hasPhotoshootsChartTarget) {
      this.charts.push(this.createPhotoshootsChart());
    }

    if (this.hasMissedChartTarget) {
      this.charts.push(this.createMissedChart());
    }

    if (this.hasLocationChartTarget) {
      this.charts.push(this.createLocationChart());
    }

    if (this.hasShootTypesChartTarget) {
      this.charts.push(this.createShootTypesChart());
    }

    if (this.hasOnlineBookingsChartTarget) {
      this.charts.push(this.createOnlineBookingsChart());
    }

    // NEW: Initialize cancelled bookings chart
    if (this.hasCancelledBookingsChartTarget) {
      this.charts.push(this.createCancelledBookingsChart());
    }

    // NEW: Initialize walk-in bookings chart
    if (this.hasWalkInBookingsChartTarget) {
      this.charts.push(this.createWalkInBookingsChart());
    }
  }

  createAppointmentsChart() {
    const data = JSON.parse(this.appointmentsChartTarget.dataset.chartData);

    return new Chart(this.appointmentsChartTarget, {
      type: 'line',
      data: {
        labels: data.map(item => item.date),
        datasets: [{
          label: 'Appointments Created',
          data: data.map(item => item.count),
          borderColor: '#4285F4',
          backgroundColor: 'rgba(66, 133, 244, 0.1)',
          fill: true,
          tension: 0.3,
          pointBackgroundColor: '#4285F4',
          pointBorderColor: '#fff',
          pointBorderWidth: 2,
          pointRadius: 4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          intersect: false,
          mode: 'index'
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              precision: 0,
              font: { size: 12 }
            },
            grid: {
              color: 'rgba(0,0,0,0.05)'
            }
          },
          x: {
            grid: {
              display: false
            }
          }
        },
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            backgroundColor: 'rgba(0,0,0,0.8)',
            titleColor: '#fff',
            bodyColor: '#fff',
            cornerRadius: 6,
            callbacks: {
              title: function(context) {
                return `Date: ${context[0].label}`;
              },
              label: function(context) {
                return `${context.dataset.label}: ${context.raw} appointments`;
              }
            }
          }
        }
      }
    });
  }

  createAppointmentsByDateChart() {
    const data = JSON.parse(this.appointmentsByDateChartTarget.dataset.chartData);

    return new Chart(this.appointmentsByDateChartTarget, {
      type: 'bar',
      data: {
        labels: data.map(item => item.date),
        datasets: [{
          label: 'Appointments by Date',
          data: data.map(item => item.count),
          backgroundColor: '#FF9800',
          borderColor: '#F57C00',
          borderWidth: 1,
          borderRadius: 4,
          borderSkipped: false
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          intersect: false,
          mode: 'index'
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              precision: 0,
              font: { size: 12 }
            },
            grid: {
              color: 'rgba(0,0,0,0.05)'
            }
          },
          x: {
            grid: {
              display: false
            }
          }
        },
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            backgroundColor: 'rgba(0,0,0,0.8)',
            titleColor: '#fff',
            bodyColor: '#fff',
            cornerRadius: 6,
            callbacks: {
              title: function(context) {
                return `Date: ${context[0].label}`;
              },
              label: function(context) {
                return `${context.dataset.label}: ${context.raw} appointments`;
              }
            }
          }
        }
      }
    });
  }

  createOnlineBookingsChart() {
    const data = JSON.parse(this.onlineBookingsChartTarget.dataset.chartData);

    return new Chart(this.onlineBookingsChartTarget, {
      type: 'line',
      data: {
        labels: data.map(item => item.date),
        datasets: [{
          label: 'Online Bookings',
          data: data.map(item => item.count),
          backgroundColor: 'rgba(156, 39, 176, 0.1)',
          borderColor: '#9C27B0',
          borderWidth: 2,
          fill: true,
          tension: 0.4,
          pointBackgroundColor: '#9C27B0',
          pointBorderColor: '#ffffff',
          pointBorderWidth: 2,
          pointRadius: 4,
          pointHoverRadius: 6
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              precision: 0,
              font: { size: 12 }
            },
            grid: {
              color: 'rgba(0,0,0,0.05)'
            }
          },
          x: {
            grid: {
              display: false
            }
          }
        },
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            backgroundColor: 'rgba(0,0,0,0.8)',
            titleColor: '#fff',
            bodyColor: '#fff',
            cornerRadius: 6,
            callbacks: {
              title: function(context) {
                return `Date: ${context[0].label}`;
              },
              label: function(context) {
                return `${context.dataset.label}: ${context.raw} bookings`;
              }
            }
          }
        }
      }
    });
  }

  // NEW: Create cancelled bookings chart
  createCancelledBookingsChart() {
    const data = JSON.parse(this.cancelledBookingsChartTarget.dataset.chartData);

    return new Chart(this.cancelledBookingsChartTarget, {
      type: 'bar',
      data: {
        labels: data.map(item => item.date),
        datasets: [{
          label: 'Cancelled Bookings',
          data: data.map(item => item.count),
          backgroundColor: '#F44336',
          borderColor: '#D32F2F',
          borderWidth: 1,
          borderRadius: 4,
          borderSkipped: false
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          intersect: false,
          mode: 'index'
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              precision: 0,
              font: { size: 12 }
            },
            grid: {
              color: 'rgba(0,0,0,0.05)'
            }
          },
          x: {
            grid: {
              display: false
            }
          }
        },
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            backgroundColor: 'rgba(0,0,0,0.8)',
            titleColor: '#fff',
            bodyColor: '#fff',
            cornerRadius: 6,
            callbacks: {
              title: function(context) {
                return `Date: ${context[0].label}`;
              },
              label: function(context) {
                return `${context.dataset.label}: ${context.raw} cancelled`;
              }
            }
          }
        }
      }
    });
  }

  // NEW: Create walk-in bookings chart
  createWalkInBookingsChart() {
    const data = JSON.parse(this.walkInBookingsChartTarget.dataset.chartData);

    return new Chart(this.walkInBookingsChartTarget, {
      type: 'line',
      data: {
        labels: data.map(item => item.date),
        datasets: [{
          label: 'Walk-in Bookings',
          data: data.map(item => item.count),
          backgroundColor: 'rgba(76, 175, 80, 0.1)',
          borderColor: '#4CAF50',
          borderWidth: 2,
          fill: true,
          tension: 0.4,
          pointBackgroundColor: '#4CAF50',
          pointBorderColor: '#ffffff',
          pointBorderWidth: 2,
          pointRadius: 4,
          pointHoverRadius: 6
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              precision: 0,
              font: { size: 12 }
            },
            grid: {
              color: 'rgba(0,0,0,0.05)'
            }
          },
          x: {
            grid: {
              display: false
            }
          }
        },
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            backgroundColor: 'rgba(0,0,0,0.8)',
            titleColor: '#fff',
            bodyColor: '#fff',
            cornerRadius: 6,
            callbacks: {
              title: function(context) {
                return `Date: ${context[0].label}`;
              },
              label: function(context) {
                return `${context.dataset.label}: ${context.raw} bookings`;
              }
            }
          }
        }
      }
    });
  }

  createPhotoshootsChart() {
    const data = JSON.parse(this.photoshootsChartTarget.dataset.chartData);

    return new Chart(this.photoshootsChartTarget, {
      type: 'line',
      data: {
        labels: data.map(item => item.date),
        datasets: [{
          label: 'Photoshoots Completed',
          data: data.map(item => item.count),
          borderColor: '#0F9D58',
          backgroundColor: 'rgba(15, 157, 88, 0.1)',
          fill: true,
          tension: 0.3,
          pointBackgroundColor: '#0F9D58',
          pointBorderColor: '#fff',
          pointBorderWidth: 2,
          pointRadius: 4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          intersect: false,
          mode: 'index'
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              precision: 0,
              font: { size: 12 }
            },
            grid: {
              color: 'rgba(0,0,0,0.05)'
            }
          },
          x: {
            grid: {
              display: false
            }
          }
        },
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            backgroundColor: 'rgba(0,0,0,0.8)',
            titleColor: '#fff',
            bodyColor: '#fff',
            cornerRadius: 6,
            callbacks: {
              title: function(context) {
                return `Date: ${context[0].label}`;
              },
              label: function(context) {
                return `${context.dataset.label}: ${context.raw} sessions`;
              }
            }
          }
        }
      }
    });
  }

  createMissedChart() {
    const data = JSON.parse(this.missedChartTarget.dataset.chartData);

    return new Chart(this.missedChartTarget, {
      type: 'bar',
      data: {
        labels: data.map(item => item.date),
        datasets: [{
          label: 'Missed Sessions',
          data: data.map(item => item.count),
          backgroundColor: '#DB4437',
          borderColor: '#B71C1C',
          borderWidth: 1,
          borderRadius: 4,
          borderSkipped: false
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              precision: 0,
              font: { size: 12 }
            },
            grid: {
              color: 'rgba(0,0,0,0.05)'
            }
          },
          x: {
            grid: {
              display: false
            }
          }
        },
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            backgroundColor: 'rgba(0,0,0,0.8)',
            titleColor: '#fff',
            bodyColor: '#fff',
            cornerRadius: 6,
            callbacks: {
              title: function(context) {
                return `Date: ${context[0].label}`;
              },
              label: function(context) {
                return `${context.dataset.label}: ${context.raw} missed`;
              }
            }
          }
        }
      }
    });
  }

  createLocationChart() {
    const data = JSON.parse(this.locationChartTarget.dataset.chartData);

    return new Chart(this.locationChartTarget, {
      type: 'bar',
      data: {
        labels: data.map(item => item.location),
        datasets: [
          {
            label: 'Appointments',
            data: data.map(item => item.appointments_created),
            backgroundColor: '#4285F4',
            borderRadius: 4,
            borderSkipped: false
          },
          {
            label: 'Completed',
            data: data.map(item => item.photoshoots_completed),
            backgroundColor: '#0F9D58',
            borderRadius: 4,
            borderSkipped: false
          },
          {
            label: 'Missed',
            data: data.map(item => item.missed_sessions),
            backgroundColor: '#DB4437',
            borderRadius: 4,
            borderSkipped: false
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          intersect: false,
          mode: 'index'
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              precision: 0,
              font: { size: 12 }
            },
            grid: {
              color: 'rgba(0,0,0,0.05)'
            }
          },
          x: {
            grid: {
              display: false
            }
          }
        },
        plugins: {
          legend: {
            position: 'top',
            align: 'end'
          },
          tooltip: {
            backgroundColor: 'rgba(0,0,0,0.8)',
            titleColor: '#fff',
            bodyColor: '#fff',
            cornerRadius: 6
          }
        }
      }
    });
  }

  createShootTypesChart() {
    const data = JSON.parse(this.shootTypesChartTarget.dataset.chartData);

    return new Chart(this.shootTypesChartTarget, {
      type: 'pie',
      data: {
        labels: data.map(item => item.shoot_type),
        datasets: [{
          data: data.map(item => item.count),
          backgroundColor: [
            '#4285F4',
            '#0F9D58',
            '#F4B400',
            '#DB4437',
            '#9C27B0',
            '#FF9800',
            '#795548'
          ],
          borderWidth: 2,
          borderColor: '#fff'
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'right',
            labels: {
              padding: 20,
              usePointStyle: true,
              font: {
                size: 12
              }
            }
          },
          tooltip: {
            backgroundColor: 'rgba(0,0,0,0.8)',
            titleColor: '#fff',
            bodyColor: '#fff',
            cornerRadius: 6,
            callbacks: {
              label: function(context) {
                const total = context.dataset.data.reduce((a, b) => a + b, 0);
                const percentage = ((context.raw / total) * 100).toFixed(1);
                return `${context.label}: ${context.raw} (${percentage}%)`;
              }
            }
          }
        }
      }
    });
  }
}
