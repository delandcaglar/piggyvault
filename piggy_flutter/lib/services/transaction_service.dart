import 'dart:async';

import 'package:piggy_flutter/model/transaction.dart';
import 'package:piggy_flutter/model/transaction_comment.dart';
import 'package:piggy_flutter/model/transaction_edit_dto.dart';
import 'package:piggy_flutter/model/transaction_group_item.dart';
import 'package:piggy_flutter/model/transaction_summary.dart';
import 'package:piggy_flutter/model/transactions_result.dart';
import 'package:piggy_flutter/services/app_service_base.dart';
import 'package:intl/intl.dart';
import 'package:piggy_flutter/services/network_service_response.dart';

class GetTransactionsInput {
  String type;
  String accountId;
  DateTime startDate;
  DateTime endDate;
  String query;
  TransactionsGroupBy groupBy;

  GetTransactionsInput(
      {this.type,
      this.accountId,
      this.startDate,
      this.endDate,
      this.groupBy}); // where the data is showing
}

class TransferInput {
  final String id, description, accountId, toAccountId, transactionTime;
  final double amount, toAmount;
  final int categoryId;

  TransferInput(this.id, this.description, this.accountId, this.transactionTime,
      this.amount, this.categoryId, this.toAmount, this.toAccountId);
}

class TransactionService extends AppServiceBase {
  Future<TransactionsResult> getTransactions(GetTransactionsInput input) async {
    List<Transaction> transactions = [];
    var result = await rest
        .postAsync<dynamic>('services/app/transaction/GetTransactionsAsync', {
      "type": input.type,
      "accountId": input.accountId,
      "startDate": input.startDate.toString(),
      "endDate": input.endDate.toString()
    });

    if (result.mappedResult != null) {
      result.mappedResult['items'].forEach((transaction) {
        transactions.add(Transaction.fromJson(transaction));
      });
    }
    return TransactionsResult(
        groupTransactions(transactions: transactions, groupBy: input.groupBy));
  }

  Future<TransactionSummary> getTransactionSummary(String duration) async {
    var result = await rest.postAsync<dynamic>(
        'services/app/tenantDashboard/GetTransactionSummary', {
      "duration": duration,
    });

    if (result.mappedResult != null) {
      return TransactionSummary.fromJson(result.mappedResult);
    }

    return null;
  }

  Future<TransactionEditDto> getTransactionForEdit(String id) async {
    var result = await rest
        .postAsync<dynamic>('services/app/transaction/GetTransactionForEdit', {
      "id": id,
    });

    if (result.mappedResult != null) {
      return TransactionEditDto.fromJson(result.mappedResult);
    }

    return null;
  }

  Future<List<TransactionComment>> getTransactionComments(String id) async {
    var comments = List<TransactionComment>();
    var result = await rest
        .postAsync<dynamic>('services/app/transaction/GetTransactionComments', {
      "id": id,
    });
    print(result.mappedResult);
    if (result.mappedResult != null) {
      result.mappedResult['items'].forEach((comment) {
        comments.add(TransactionComment.fromJson(comment));
      });
    }

    return comments;
  }

  Future<NetworkServiceResponse<dynamic>> createOrUpdateTransaction(
      TransactionEditDto input) async {
    final result = await rest
        .postAsync('services/app/transaction/CreateOrUpdateTransaction', {
      "id": input.id,
      "description": input.description,
      "amount": input.amount,
      "categoryId": input.categoryId,
      "accountId": input.accountId,
      "transactionTime": input.transactionTime
    });

    return result.networkServiceResponse;
  }

  Future<Null> saveTransactionComment(
      String transactionId, String content) async {
    await rest.postAsync(
        'services/app/transaction/CreateOrUpdateTransactionCommentAsync', {
      "transactionId": transactionId,
      "content": content,
    });
  }

  Future<Null> transfer(TransferInput input) async {
    await rest.postAsync('services/app/transaction/TransferAsync', {
      "id": input.id,
      "description": input.description,
      "amount": input.amount,
      "toAmount": input.toAmount,
      "categoryId": input.categoryId,
      "accountId": input.accountId,
      "toAccountId": input.toAccountId,
      "transactionTime": input.transactionTime
    });
  }

  List<TransactionGroupItem> groupTransactions(
      {List<Transaction> transactions,
      TransactionsGroupBy groupBy = TransactionsGroupBy.Date}) {
    List<TransactionGroupItem> sections = [];
    var formatter = DateFormat("EEE, MMM d, ''yy");
    String key;

    transactions.forEach((transaction) {
      if (groupBy == TransactionsGroupBy.Date) {
        key = formatter.format(DateTime.parse(transaction.transactionTime));
      } else if (groupBy == TransactionsGroupBy.Category) {
        key = transaction.categoryName;
      }

      var section =
          sections.firstWhere((o) => o.title == key, orElse: () => null);

      if (section == null) {
        section = TransactionGroupItem(title: key, groupby: groupBy);
        sections.add(section);
      }

      if (transaction.amountInDefaultCurrency > 0) {
        section.totalInflow += transaction.amountInDefaultCurrency;
      } else {
        section.totalOutflow += transaction.amountInDefaultCurrency;
      }

      section.transactions.add(transaction);
    });

    return sections;
  }
}