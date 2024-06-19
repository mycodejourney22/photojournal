// app/javascript/controllers/chart_controller.js

import { Controller } from "@hotwired/stimulus"
import { Chart, registerables  } from "chart.js"
Chart.register(...registerables ); // Import 'chart.js/auto' for full Chart.js functionality

export default class extends Controller {
  connect() {
    const canvas = this.element;
    const ctx = canvas.getContext("2d");
    canvas.width = 400; // Adjust width as needed
    canvas.height = 400;
    if (this.element.dataset.chartData) {
      const data = JSON.parse(this.element.dataset.chartData);
      this.buildchart(data, ctx, "Total Selections by Editor");
    }

    if (this.element.dataset.photographerChartData) {
      const data = JSON.parse(this.element.dataset.photographerChartData);
      this.buildchart(data, ctx, "Total Shoots by Photographer");
    }



    if (this.element.dataset.locationChartData) {
      // const ctx = this.element.getContext("2d");
      const canva = this.element;
      const cts = canva.getContext("2d");
      canva.width = 200; // Adjust width as needed
      canva.height = 200;
      const data = JSON.parse(this.element.dataset.locationChartData);
      this.buildPieChart(data, cts, "Photoshoots Count by Location");
    }

  }




  buildchart(data, ctx, label){
    return new Chart(ctx, {
      type: "bar",
      data: {
        labels: data.map(item => item.name?.name),
        datasets: [
          {
            label: label,
            data: data.map(item => item.y),
            backgroundColor: "rgba(75, 192, 192, 0.2)",
            borderColor: "rgba(75, 192, 192, 1)",
            borderWidth: 1,
          },
        ],
      },
      options: {
        indexAxis: 'y',
        scales: {
          y: {
            beginAtZero: true,
            grid: {
              display: false // Disable grid lines on the x-axis
            }
          },
          x:{
            grid: {
              display: false // Disable grid lines on the y-axis
            }
          }
        },
      },
    });
  }

  buildPieChart(data, ctx, label) {
    return new Chart(ctx, {
      type: "pie",
      data: {
        labels: data.map(item => item.name),
        datasets: [{
          label: label,
          data: data.map(item => item.y),
          backgroundColor: [
            "rgba(255, 99, 132, 0.2)",
            "rgba(54, 162, 235, 0.2)",
            "rgba(255, 206, 86, 0.2)",
            "rgba(75, 192, 192, 0.2)",
            "rgba(153, 102, 255, 0.2)",
            "rgba(255, 159, 64, 0.2)"
          ],
          borderColor: [
            "rgba(255, 99, 132, 1)",
            "rgba(54, 162, 235, 1)",
            "rgba(255, 206, 86, 1)",
            "rgba(75, 192, 192, 1)",
            "rgba(153, 102, 255, 1)",
            "rgba(255, 159, 64, 1)"
          ],
          borderWidth: 1,
        }],
      },
      options: {
        responsive: true,
        plugins: {
          legend: {
            position: 'top',
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                let label = context.label || '';

                if (label) {
                  label += ': ';
                }
                if (context.parsed !== null) {
                  label += context.parsed;
                }
                return label;
              }
            }
          }
        }
      },
    });
  }
}
