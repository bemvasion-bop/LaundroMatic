import '../models/order.dart';

class AiReportData {
  final int totalOrders;
  final int completedOrders;
  final int inProgressOrders;
  final int cancelledOrders;
  final int paidOrders;
  final double totalRevenue;
  final double unpaidRevenue;
  final double totalWeight;
  final double avgTicket;
  final double avgWeight;
  final double completionRate;
  final double paymentRate;
  final String efficiencyGrade;
  final DateTime generatedAt;
  final String businessName;

  AiReportData({
    required this.totalOrders,
    required this.completedOrders,
    required this.inProgressOrders,
    required this.cancelledOrders,
    required this.paidOrders,
    required this.totalRevenue,
    required this.unpaidRevenue,
    required this.totalWeight,
    required this.avgTicket,
    required this.avgWeight,
    required this.completionRate,
    required this.paymentRate,
    required this.efficiencyGrade,
    required this.generatedAt,
    required this.businessName,
  });

  factory AiReportData.fromOrders(
    List<LaundryOrder> orders, {
    String businessName = 'LaundroMatic Laundromat',
  }) {
    final totalOrders = orders.length;
    int completedOrders = 0;
    int inProgressOrders = 0;
    int cancelledOrders = 0;
    int paidOrders = 0;
    double totalRevenue = 0.0;
    double unpaidRevenue = 0.0;
    double totalWeight = 0.0;

    for (final o in orders) {
      if (o.orderStatus == 'Picked Up') {
        completedOrders++;
      } else if (o.orderStatus == 'Cancelled') {
        cancelledOrders++;
      } else {
        inProgressOrders++;
      }

      if (o.paymentStatus == 'Paid') {
        paidOrders++;
        totalRevenue += o.totalAmount;
      } else {
        unpaidRevenue += o.totalAmount;
      }

      totalWeight += o.weight;
    }

    final double completionRate =
        totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0.0;
    final double paymentRate =
        totalOrders > 0 ? (paidOrders / totalOrders) * 100 : 0.0;
    final double avgTicket =
        totalOrders > 0 ? totalRevenue / (paidOrders > 0 ? paidOrders : 1) : 0.0;
    final double avgWeight = totalOrders > 0 ? totalWeight / totalOrders : 0.0;

    String grade = 'A+ (Optimal)';
    if (completionRate < 60) {
      grade = 'B (In Progress)';
    } else if (completionRate < 80) {
      grade = 'A- (High Performing)';
    }

    return AiReportData(
      totalOrders: totalOrders,
      completedOrders: completedOrders,
      inProgressOrders: inProgressOrders,
      cancelledOrders: cancelledOrders,
      paidOrders: paidOrders,
      totalRevenue: totalRevenue,
      unpaidRevenue: unpaidRevenue,
      totalWeight: totalWeight,
      avgTicket: avgTicket,
      avgWeight: avgWeight,
      completionRate: completionRate,
      paymentRate: paymentRate,
      efficiencyGrade: grade,
      generatedAt: DateTime.now(),
      businessName: businessName,
    );
  }
}

class AiReportGenerator {
  static String formatTimestamp(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hour:$min';
  }

  static String generateMarkdownSummary(AiReportData data) {
    final dateStr = formatTimestamp(data.generatedAt);
    return '''# LAUNDROMATIC BUSINESS PERFORMANCE REPORT
**Business Operations Summary**
- **Business**: ${data.businessName}
- **Generated On**: $dateStr
- **Order Fulfillment Rate**: ${data.completionRate.toStringAsFixed(1)}%
- **Payment Collection Rate**: ${data.paymentRate.toStringAsFixed(1)}%

---

## 1. Executive Summary
Over the observed operational period, ${data.businessName} sustained consistent order flow across ${data.totalOrders} recorded transactions. Gross realized revenue reached ₱${data.totalRevenue.toStringAsFixed(2)} with an average customer spend of ₱${data.avgTicket.toStringAsFixed(2)} per order. A total throughput of ${data.totalWeight.toStringAsFixed(1)} kg was processed through laundry staging, maintaining a ${data.paymentRate.toStringAsFixed(1)}% payment collection rate.

---

## 2. Key Performance Indicators
- **Realized Revenue**: ₱${data.totalRevenue.toStringAsFixed(2)}
- **Pending/Uncollected Revenue**: ₱${data.unpaidRevenue.toStringAsFixed(2)}
- **Total Volume Handled**: ${data.totalWeight.toStringAsFixed(1)} kg
- **Average Ticket Value**: ₱${data.avgTicket.toStringAsFixed(2)}
- **Average Load Per Order**: ${data.avgWeight.toStringAsFixed(1)} kg
- **Completed Orders**: ${data.completedOrders} / ${data.totalOrders} (${data.completionRate.toStringAsFixed(1)}%)
- **Active Orders in Pipeline**: ${data.inProgressOrders}

---

## 3. Operational Highlights & Notes
1. **Capacity & Equipment Load**: Average load capacity is ${data.avgWeight.toStringAsFixed(1)} kg per order. Standard wash cycles are operating within recommended equipment limits.
2. **Payment Collection**: ${data.paymentRate.toStringAsFixed(1)}% of orders are settled upon drop-off or pickup.
3. **Turnaround & Staging**: There are currently ${data.inProgressOrders} active orders in staging. Maintain pickup notifications to ensure prompt customer collections.

*Generated by LaundroMatic Management System.*''';
  }

  static String generateCsvData(List<LaundryOrder> orders) {
    final buffer = StringBuffer();
    buffer.writeln(
        'Order ID,Date,Weight (kg),Service Amount,Detergent Amount,Conditioner Amount,Total Amount,Payment Status,Order Status');

    for (final o in orders) {
      final dateStr = o.orderDate != null
          ? '${o.orderDate!.year}-${o.orderDate!.month.toString().padLeft(2, '0')}-${o.orderDate!.day.toString().padLeft(2, '0')}'
          : 'N/A';
      buffer.writeln(
          '"${o.orderId}","$dateStr",${o.weight},${o.serviceTotal},${o.detergentFee},${o.conditionerFee},${o.totalAmount},"${o.paymentStatus}","${o.orderStatus}"');
    }

    return buffer.toString();
  }

  static String generateAiHtmlReport(
    AiReportData data,
    List<LaundryOrder> orders,
  ) {
    final dateStr = formatTimestamp(data.generatedAt);

    // Build order rows
    final StringBuffer tableRows = StringBuffer();
    for (int i = 0; i < orders.length && i < 50; i++) {
      final o = orders[i];
      final orderDate = o.orderDate != null
          ? '${o.orderDate!.month}/${o.orderDate!.day}/${o.orderDate!.year}'
          : '-';
      final isPaid = o.paymentStatus == 'Paid';
      final isCompleted = o.orderStatus == 'Picked Up';

      tableRows.writeln('''
        <tr>
          <td><span class="mono">${o.orderId.length > 8 ? o.orderId.substring(0, 8) : o.orderId}</span></td>
          <td>$orderDate</td>
          <td>${o.weight.toStringAsFixed(1)} kg</td>
          <td>₱${o.totalAmount.toStringAsFixed(2)}</td>
          <td><span class="badge ${isPaid ? 'badge-success' : 'badge-warning'}">${o.paymentStatus}</span></td>
          <td><span class="badge ${isCompleted ? 'badge-primary' : 'badge-info'}">${o.orderStatus}</span></td>
        </tr>
      ''');
    }

    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>LaundroMatic Business Performance Report</title>
  <style>
    :root {
      --primary: #1E64D4;
      --primary-light: #EBF2FE;
      --dark: #0F172A;
      --card-bg: #FFFFFF;
      --bg: #F8FAFC;
      --border: #E2E8F0;
      --text-muted: #64748B;
      --success: #16A34A;
      --success-light: #DCFCE7;
      --warning: #D97706;
      --warning-light: #FEF3C7;
      --purple: #9333EA;
      --purple-light: #F3E8FF;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background-color: var(--bg);
      color: var(--dark);
      padding: 32px 16px;
      line-height: 1.5;
    }
    .container {
      max-width: 900px;
      margin: 0 auto;
      background: var(--card-bg);
      border-radius: 20px;
      border: 1px solid var(--border);
      box-shadow: 0 10px 30px rgba(0,0,0,0.05);
      padding: 36px;
    }
    .header-bar {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      border-bottom: 1px solid var(--border);
      padding-bottom: 24px;
      margin-bottom: 24px;
    }
    .report-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: var(--primary);
      color: white;
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.8px;
      padding: 5px 12px;
      border-radius: 100px;
      margin-bottom: 10px;
    }
    h1 {
      font-size: 26px;
      font-weight: 800;
      color: var(--dark);
      letter-spacing: -0.5px;
    }
    .meta-subtitle {
      color: var(--text-muted);
      font-size: 13px;
      margin-top: 4px;
    }
    .actions-bar {
      display: flex;
      gap: 10px;
    }
    .btn {
      padding: 8px 16px;
      border-radius: 10px;
      font-size: 13px;
      font-weight: 600;
      cursor: pointer;
      text-decoration: none;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      transition: all 0.2s;
    }
    .btn-primary {
      background: var(--primary);
      color: white;
      border: none;
    }
    .btn-primary:hover { opacity: 0.9; transform: translateY(-1px); }
    .btn-outline {
      background: white;
      color: var(--dark);
      border: 1px solid var(--border);
    }
    
    /* Executive Summary */
    .executive-card {
      background: linear-gradient(135deg, #F0F7FF 0%, #FAF5FF 100%);
      border: 1px solid #DBEAFE;
      border-radius: 16px;
      padding: 20px;
      margin-bottom: 24px;
      position: relative;
    }
    .executive-card h2 {
      font-size: 15px;
      font-weight: 700;
      color: #1E3A8A;
      display: flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 10px;
    }
    .executive-card p {
      font-size: 13.5px;
      color: #334155;
      line-height: 1.6;
    }

    /* KPI Matrix */
    .kpi-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
      margin-bottom: 28px;
    }
    .kpi-card {
      background: #FFFFFF;
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 16px;
      box-shadow: 0 2px 6px rgba(0,0,0,0.02);
    }
    .kpi-label {
      font-size: 12px;
      font-weight: 600;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .kpi-value {
      font-size: 22px;
      font-weight: 800;
      color: var(--dark);
      margin-top: 6px;
    }
    .kpi-sub {
      font-size: 11.5px;
      margin-top: 4px;
      display: flex;
      align-items: center;
      gap: 4px;
    }

    /* Recommendations */
    .section-title {
      font-size: 16px;
      font-weight: 700;
      color: var(--dark);
      margin-bottom: 14px;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .ai-insights {
      display: flex;
      flex-direction: column;
      gap: 12px;
      margin-bottom: 28px;
    }
    .insight-card {
      background: #F8FAFC;
      border-left: 4px solid var(--primary);
      border-radius: 4px 12px 12px 4px;
      padding: 14px 18px;
    }
    .insight-title {
      font-size: 13.5px;
      font-weight: 700;
      color: var(--dark);
      margin-bottom: 4px;
    }
    .insight-body {
      font-size: 12.5px;
      color: #475569;
    }

    /* Table */
    .table-container {
      overflow-x: auto;
      border: 1px solid var(--border);
      border-radius: 12px;
      margin-bottom: 28px;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      text-align: left;
      font-size: 12.5px;
    }
    th {
      background: #F8FAFC;
      padding: 12px 14px;
      font-weight: 600;
      color: var(--text-muted);
      border-bottom: 1px solid var(--border);
    }
    td {
      padding: 12px 14px;
      border-bottom: 1px solid var(--border);
      color: #334155;
    }
    tr:last-child td { border-bottom: none; }
    .mono { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 11.5px; }
    .badge {
      display: inline-block;
      padding: 2px 8px;
      border-radius: 6px;
      font-size: 11px;
      font-weight: 600;
    }
    .badge-success { background: var(--success-light); color: var(--success); }
    .badge-warning { background: var(--warning-light); color: var(--warning); }
    .badge-primary { background: var(--primary-light); color: var(--primary); }
    .badge-info { background: #E0F2FE; color: #0284C7; }

    /* Footer */
    .footer {
      border-top: 1px solid var(--border);
      padding-top: 18px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 11.5px;
      color: var(--text-muted);
    }

    @media print {
      body { background: white; padding: 0; }
      .container { border: none; box-shadow: none; padding: 0; }
      .actions-bar { display: none; }
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header-bar">
      <div>
        <div class="report-badge">OPERATIONAL PERFORMANCE REPORT</div>
        <h1>LaundroMatic Operational Report</h1>
        <div class="meta-subtitle">${data.businessName} • Generated on $dateStr • ${data.totalOrders} Total Recorded Orders</div>
      </div>
      <div class="actions-bar">
        <button class="btn btn-primary" onclick="window.print()">🖨 Print / Save as PDF</button>
      </div>
    </div>

    <!-- Executive Summary Card -->
    <div class="executive-card">
      <h2>Executive Summary</h2>
      <p>
        During the current evaluation cycle, <strong>${data.businessName}</strong> demonstrated stable operational performance with <strong>${data.totalOrders} total recorded orders</strong> and a cumulative laundry weight throughput of <strong>${data.totalWeight.toStringAsFixed(1)} kg</strong>. Realized gross revenue stands at <strong>₱${data.totalRevenue.toStringAsFixed(2)}</strong> with an average ticket value of <strong>₱${data.avgTicket.toStringAsFixed(2)}</strong>. Operational fulfillment currently holds at <strong>${data.completionRate.toStringAsFixed(1)}%</strong> completion with <strong>${data.paymentRate.toStringAsFixed(1)}% collection stability</strong>.
      </p>
    </div>

    <!-- KPI Matrix -->
    <div class="kpi-grid">
      <div class="kpi-card">
        <div class="kpi-label">Realized Revenue</div>
        <div class="kpi-value" style="color: #16A34A;">₱${data.totalRevenue.toStringAsFixed(2)}</div>
        <div class="kpi-sub" style="color: #64748B;">Pending: ₱${data.unpaidRevenue.toStringAsFixed(2)}</div>
      </div>
      <div class="kpi-card">
        <div class="kpi-label">Volume Processed</div>
        <div class="kpi-value" style="color: #1E64D4;">${data.totalWeight.toStringAsFixed(1)} kg</div>
        <div class="kpi-sub" style="color: #64748B;">Avg load: ${data.avgWeight.toStringAsFixed(1)} kg/order</div>
      </div>
      <div class="kpi-card">
        <div class="kpi-label">Completed Orders</div>
        <div class="kpi-value" style="color: #9333EA;">${data.completedOrders}</div>
        <div class="kpi-sub" style="color: #16A34A;">${data.completionRate.toStringAsFixed(1)}% fulfillment rate</div>
      </div>
      <div class="kpi-card">
        <div class="kpi-label">Average Ticket</div>
        <div class="kpi-value" style="color: #D97706;">₱${data.avgTicket.toStringAsFixed(2)}</div>
        <div class="kpi-sub" style="color: #64748B;">Per customer order</div>
      </div>
    </div>

    <!-- Operational Highlights -->
    <div class="section-title">Operational Highlights & Capacity Metrics</div>
    <div class="ai-insights">
      <div class="insight-card" style="border-left-color: #16A34A;">
        <div class="insight-title">Revenue Realization & Ticket Health</div>
        <div class="insight-body">
          Current payment collection efficiency is at <strong>${data.paymentRate.toStringAsFixed(1)}%</strong>. Average customer spend of <strong>₱${data.avgTicket.toStringAsFixed(2)}</strong> reflects steady utilization of services and detergent/conditioner add-ons.
        </div>
      </div>
      <div class="insight-card" style="border-left-color: #1E64D4;">
        <div class="insight-title">Machine Throughput & Load Balancing</div>
        <div class="insight-body">
          Average load weight per order is <strong>${data.avgWeight.toStringAsFixed(1)} kg</strong> across <strong>${data.totalWeight.toStringAsFixed(1)} kg</strong> total processed volume. Washing equipment operates smoothly within recommended drum capacity.
        </div>
      </div>
      <div class="insight-card" style="border-left-color: #9333EA;">
        <div class="insight-title">Fulfillment Velocity & Customer Turnaround</div>
        <div class="insight-body">
          There are currently <strong>${data.inProgressOrders} active orders</strong> in the processing pipeline and <strong>${data.completedOrders} completed orders</strong>. Customer notifications when laundry is ready ensure prompt customer pickup.
        </div>
      </div>
    </div>

    <!-- Recent Orders Table -->
    <div class="section-title">Order Log & Financial Breakdown (Recent Transactions)</div>
    <div class="table-container">
      <table>
        <thead>
          <tr>
            <th>Order Ref</th>
            <th>Date</th>
            <th>Weight</th>
            <th>Amount</th>
            <th>Payment</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          $tableRows
        </tbody>
      </table>
    </div>

    <!-- Footer -->
    <div class="footer">
      <div>LaundroMatic Management System • Operations Report • Confidential</div>
      <div>Generated on $dateStr</div>
    </div>
  </div>
</body>
</html>''';
  }
}
