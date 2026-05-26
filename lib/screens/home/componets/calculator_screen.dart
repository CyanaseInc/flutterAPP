import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

class CalculatorScreen extends StatefulWidget {
  final Map<String, dynamic> selectedClass;
  final Map<String, dynamic> selectedOption;
  final VoidCallback onProceedToPayment;

  const CalculatorScreen({
    Key? key,
    required this.selectedClass,
    required this.selectedOption,
    required this.onProceedToPayment,
  }) : super(key: key);

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  TextEditingController _amountController = TextEditingController();
  double _estimatedReturn = 0.0;
  double _enteredAmount = 0.0;

  @override
  void initState() {
    super.initState();
    // Don't pre-fill - leave empty for user input
    _amountController.addListener(_calculateReturn);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _calculateReturn() {
    final interestRate = double.tryParse(widget.selectedOption['interest']?.toString() ?? '0') ?? 0;
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    _enteredAmount = amount;
    
    setState(() {
      _estimatedReturn = amount + (amount * (interestRate / 100));
    });
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _showCalculatorModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCalculatorModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedFundClass = widget.selectedClass['investment_class'] as String?;
    final selectedOptionName = widget.selectedOption['investment_option'] as String?;
    final optionDescription = widget.selectedOption['description'] as String?;
    final interestRate = double.tryParse(widget.selectedOption['interest']?.toString() ?? '0') ?? 0;
    final minDeposit = widget.selectedOption['minimum_deposit'] ?? 0;
    final maturity  = widget.selectedOption['maturity'] ?? 'N/A';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: [
              // Selected Option Summary - Single Column
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Option Name
                    Text(
                      selectedOptionName ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: primaryTwo,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Class
                    Text(
                      'Class: $selectedFundClass',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Divider
                    Divider(
                      color: Colors.grey[200],
                      height: 1,
                    ),
                    const SizedBox(height: 20),
                    
                    // All details in single column
                    _buildDetailRow(Icons.attach_money, 'Minimum Deposit:', 'USh ${_formatNumber(minDeposit.toDouble())}'),
                    const SizedBox(height: 12),
                    
                    _buildDetailRow(Icons.trending_up, 'Interest Rate:', '${interestRate}%'),
                    const SizedBox(height: 12),
                    
                    _buildDetailRow(Icons.business, 'Description:', optionDescription?? 'N/A'),
                    const SizedBox(height: 12),
                    
                    _buildDetailRow(Icons.credit_card, 'Available maturity:', '${maturity.toString()} months'),
                  ],
                ),
              ),
              

              // Action Buttons in a Row
              Row(
                children: [
                  // Calculate Returns Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showCalculatorModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTwo.withOpacity(0.1),
                        foregroundColor: primaryTwo,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: primaryTwo, width: 1.5),
                        ),
                      ),
                      icon: const Icon(Icons.calculate, size: 15),
                      label: const Text(
                        'CALCULATE',
                        style: TextStyle(
                          fontSize: 15,

                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Buy Now Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onProceedToPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTwo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'BUY',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }

  Widget _buildCalculatorModal() {
    final interestRate = double.tryParse(widget.selectedOption['interest']?.toString() ?? '0') ?? 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Investment Calculator',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Amount Input Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INVESTMENT AMOUNT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  onChanged: (value) => _calculateReturn(), // Live calculation
                  decoration: InputDecoration(
                    
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryTwo, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              
            
              ],
            ),
            const SizedBox(height: 24),

            // Live Returns Display (shows even while typing)
            if (_enteredAmount > 0) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryTwo.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryTwo.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      'PROJECTED RETURNS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryTwo,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Investment Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Investment:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'USh ${_formatNumber(_enteredAmount)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Interest Rate
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Interest Rate:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${interestRate}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Divider(color: primaryTwo.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    
                    // Maturity Value
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Maturity Value:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'USh ${_formatNumber(_estimatedReturn)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: primaryTwo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Total Return
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Total return: USh ${_formatNumber(_estimatedReturn - _enteredAmount)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              // Placeholder when no amount entered
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.calculate_outlined,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Enter amount to see projected returns',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Buy With This Amount Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enteredAmount > 0
                    ? () {
                        Navigator.pop(context);
                        widget.onProceedToPayment();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTwo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'BUY WITH THIS AMOUNT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: primaryTwo,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

}