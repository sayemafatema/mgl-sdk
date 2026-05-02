'use client'

import React from 'react'

class ErrorBoundary extends React.Component<
  { children: React.ReactNode },
  { error: Error | null }
> {
  constructor(props: any) {
    super(props)
    this.state = { error: null }
  }

  static getDerivedStateFromError(error: Error) {
    return { error }
  }

  render() {
    if (this.state.error) {
      return (
        <div className="p-6 bg-red-50 border border-red-200 rounded-xl">
          <p className="font-bold text-red-700 mb-2">Driver page crash:</p>
          <p className="text-sm font-mono text-red-600">{this.state.error.message}</p>
          <pre className="text-xs text-red-500 mt-2 overflow-auto">{this.state.error.stack}</pre>
        </div>
      )
    }
    return this.props.children
  }
}

function FODriversViewInner() {
  const drivers = [
    { id: 1, name: 'Ramesh Kumar', vrn: 'MH 02 AB 1234', status: 'Active', balance: '₹12,500' },
    { id: 2, name: 'Priya Patel', vrn: 'MH 02 CD 5678', status: 'Active', balance: '₹8,200' },
    { id: 3, name: 'Suresh Singh', vrn: 'MH 02 EF 9012', status: 'Inactive', balance: '₹5,100' },
  ]

  return (
    <div className="w-full max-w-6xl mx-auto p-6">
      <h1 className="text-3xl font-bold text-gray-900 mb-6">Fleet Drivers</h1>

      <div className="bg-white rounded-lg border border-gray-200 shadow-sm overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Driver Name</th>
              <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Vehicle (VRN)</th>
              <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Status</th>
              <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Card Balance</th>
              <th className="px-6 py-3 text-center text-sm font-semibold text-gray-700">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {drivers.map((driver) => (
              <tr key={driver.id} className="hover:bg-gray-50 transition">
                <td className="px-6 py-4 text-sm text-gray-900 font-medium">{driver.name}</td>
                <td className="px-6 py-4 text-sm text-gray-600">{driver.vrn}</td>
                <td className="px-6 py-4 text-sm">
                  <span
                    className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-medium ${
                      driver.status === 'Active' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-700'
                    }`}
                  >
                    {driver.status}
                  </span>
                </td>
                <td className="px-6 py-4 text-sm font-semibold text-gray-900">{driver.balance}</td>
                <td className="px-6 py-4 text-center">
                  <button className="text-green-700 hover:text-green-800 font-medium text-sm">View Details</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

export default function FODriversView() {
  return (
    <ErrorBoundary>
      <FODriversViewInner />
    </ErrorBoundary>
  )
}
