import React, { useState, useEffect, useRef } from 'react'
import Chart from 'chart.js'
import { useInterval } from './hooks/useInterval'
import logo from './logo.png'
import './App.scss'

function App () {
  const [datasets, setDatasets] = useState([])
  const chartRef = useRef(null)
  const chartId = 'HeartrateChart'
  const maxNbPoints = 100
  const colorArray = [
    'rgba(255, 0, 0, 1)',
    'rgba(0, 0, 255, 1)',
    'rgba(0, 255, 0, 1)'
  ]
  const apiUrl = '/api/heartrate'

  const mapDataset = (dataset, idx) => {
    const colorIdx = idx % colorArray.length
    const color = colorArray[colorIdx]
    const fillColor = color.slice().replace(', 1)', ', 0.1)')
    if (dataset.data.length >= maxNbPoints) {
      dataset.data = dataset.data.slice(0, maxNbPoints)
    } else {
      const filler = Array(maxNbPoints - dataset.data.length).fill(0)
      dataset.data = dataset.data.concat(filler)
    }

    dataset.backgroundColor = fillColor
    dataset.borderColor = color
    dataset.pointBackgroundColor = color
    dataset.pointBorderColor = color

    return dataset
  }

  useInterval(() => {
    window.fetch(apiUrl)
      .then(res => res.json())
      .then(newDatasets => {
        return newDatasets.map(mapDataset)
      })
      .then(setDatasets)
  }, [1000])

  useEffect(() => {
    chartRef.current = new Chart(chartId, {
      type: 'line',
      data: {
        labels: [],
        datasets: []
      },
      options: {
        animation: false,
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          xAxes: [{
            ticks: { display: false }
          }]
        },
        title: {
          display: true,
          text: 'Heart rate (in bpm)'
        }
      }
    })
  }, [])

  useEffect(() => {
    const chart = chartRef.current
    if (!chart) return
    chart.data.labels = Array(maxNbPoints).fill(0)
    chart.data.datasets = datasets
    chart.update()
  }, [datasets, chartRef])

  return (
    <div className='container'>
      <nav className='navbar navbar-expand-lg navbar-light'>
        <a className='navbar-brand logo' href='/'><img src={logo} alt='Edgeworx logo' /></a>
      </nav>
      <div>
        <canvas id={chartId} className='chart' />
      </div>
    </div>
  )
}

export default App
