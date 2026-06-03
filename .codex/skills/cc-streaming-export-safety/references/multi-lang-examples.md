# 流式导出 / 大对象内存安全 - 多语言完整示例

## Excel 流式写入

### Java (Apache POI SXSSF)

```java
SXSSFWorkbook wb = null;
try {
    wb = new SXSSFWorkbook(100);
    wb.setCompressTempFiles(true);
    Sheet sheet = wb.createSheet("orders");

    Row header = sheet.createRow(0);
    header.createCell(0).setCellValue("id");
    header.createCell(1).setCellValue("amount");

    int rowIdx = 1;
    int page = 0;
    Page<Order> orderPage;
    do {
        orderPage = orderRepo.findAll(PageRequest.of(page++, 1000));
        for (Order o : orderPage.getContent()) {
            Row row = sheet.createRow(rowIdx++);
            row.createCell(0).setCellValue(o.getId());
            row.createCell(1).setCellValue(o.getAmount().doubleValue());
        }
    } while (orderPage.hasNext());

    try (OutputStream os = new FileOutputStream("orders.xlsx")) {
        wb.write(os);
    }
} finally {
    if (wb != null) {
        wb.dispose();
    }
}
```

### Java (EasyExcel - 阿里，已使用项目)

```java
ExcelWriter writer = null;
try {
    writer = EasyExcel.write("orders.xlsx", OrderDTO.class).build();
    WriteSheet sheet = EasyExcel.writerSheet("orders")
            .registerWriteHandler(new LongestMatchColumnWidthStyleStrategy())
            .build();

    int pageNo = 0;
    while (true) {
        List<OrderDTO> batch = orderRepo.findAll(PageRequest.of(pageNo++, 1000))
                .map(this::toDTO)
                .getContent();
        if (batch.isEmpty()) {
            break;
        }
        writer.write(batch, sheet);
    }
} finally {
    if (writer != null) {
        writer.finish();
    }
}
```

> EasyExcel 已进入维护模式。新项目优先评估 Apache POI SXSSF、FastExcel / Apache Fesod 或项目已有导出栈。

### Python (openpyxl write_only)

```python
from openpyxl import Workbook

wb = Workbook(write_only=True)
ws = wb.create_sheet("orders")

ws.append(["id", "amount"])

page = 0
while True:
    orders = order_repo.find_page(page, 1000)
    if not orders:
        break
    for o in orders:
        ws.append([o.id, float(o.amount)])
    page += 1

wb.save("orders.xlsx")
```

**陷阱**：write_only 模式下不能用 `ws.cell(row=1, column=1, value="x")`，只能 `ws.append([...])`。

### Python (pandas 边界)

```python
import pandas as pd

# pandas 适合 CSV 分块读写；不适合把超大 xlsx 当成真正流式导出方案。
# 超大 Excel 写入优先使用 openpyxl write_only，超大数据交换优先考虑 CSV / JSONL。
for chunk in pd.read_csv("orders.csv", chunksize=10000):
    process(chunk)
```

### Go (excelize StreamWriter)

```go
package main

import (
    "fmt"
    "github.com/xuri/excelize/v2"
)

func exportOrders(orders []Order) error {
    f := excelize.NewFile()
    defer f.Close()

    sw, err := f.NewStreamWriter("Sheet1")
    if err != nil {
        return err
    }

    if err := sw.SetRow("A1", []interface{}{"id", "amount"}); err != nil {
        return err
    }

    for i, o := range orders {
        cell, _ := excelize.CoordinatesToCellName(1, i+2)
        if err := sw.SetRow(cell, []interface{}{o.ID, o.Amount}); err != nil {
            return err
        }
    }

    if err := sw.Flush(); err != nil {
        return err
    }
    return f.SaveAs("orders.xlsx")
}
```

**陷阱**：忘记 `sw.Flush()` 数据全在 buffer 里。

### Node.js (ExcelJS stream)

```typescript
import ExcelJS from 'exceljs';

async function exportOrders(orders: Order[]) {
    const workbook = new ExcelJS.stream.xlsx.WorkbookWriter({
        filename: 'orders.xlsx',
        useStyles: true,
    });
    const ws = workbook.addWorksheet('orders');

    ws.addRow(['id', 'amount']).commit();

    for (const o of orders) {
        ws.addRow([o.id, o.amount]).commit();
    }

    ws.commit();
    await workbook.commit();
}
```

---

## CSV 流式写入

### Java (OpenCSV)

```java
try (CSVWriter writer = new CSVWriter(
        new BufferedWriter(new FileWriter("orders.csv")))) {
    writer.writeNext(new String[]{"id", "amount"});

    int page = 0;
    Page<Order> orderPage;
    do {
        orderPage = orderRepo.findAll(PageRequest.of(page++, 1000));
        for (Order o : orderPage.getContent()) {
            writer.writeNext(new String[]{
                String.valueOf(o.getId()),
                o.getAmount().toPlainString()
            });
        }
    } while (orderPage.hasNext());
}
```

### Python (csv.writer 迭代)

```python
import csv

with open("orders.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["id", "amount"])

    page = 0
    while True:
        orders = order_repo.find_page(page, 10000)
        if not orders:
            break
        writer.writerows((o.id, o.amount) for o in orders)
        page += 1
```

### Go (encoding/csv)

```go
import (
    "encoding/csv"
    "os"
)

func exportCSV(orders []Order) error {
    f, err := os.Create("orders.csv")
    if err != nil {
        return err
    }
    defer f.Close()

    w := csv.NewWriter(f)
    defer w.Flush()

    if err := w.Write([]string{"id", "amount"}); err != nil {
        return err
    }

    for _, o := range orders {
        if err := w.Write([]string{
            strconv.FormatInt(o.ID, 10),
            o.Amount.String(),
        }); err != nil {
            return err
        }
    }
    return w.Error()
}
```

**陷阱**：`defer w.Flush()` 必须有，否则 buffer 内的数据不会落盘。

### Node.js (csv-stringify stream)

```typescript
import { stringify } from 'csv-stringify';
import { createWriteStream } from 'fs';
import { pipeline } from 'stream/promises';

async function exportCSV(orders: Order[]) {
    const stringifier = stringify({ header: true });
    const output = createWriteStream('orders.csv');

    const writePromise = pipeline(stringifier, output);

    for (const o of orders) {
        if (!stringifier.write({ id: o.id, amount: o.amount })) {
            await new Promise(resolve => stringifier.once('drain', resolve));
        }
    }
    stringifier.end();
    await writePromise;
}
```

---

## JSON 流式写入

### Java (Jackson JsonGenerator)

```java
ObjectMapper mapper = new ObjectMapper();
try (JsonGenerator gen = mapper.getFactory()
        .createGenerator(new FileOutputStream("orders.json"), JsonEncoding.UTF8)) {
    gen.writeStartArray();

    int page = 0;
    Page<Order> orderPage;
    do {
        orderPage = orderRepo.findAll(PageRequest.of(page++, 1000));
        for (Order o : orderPage.getContent()) {
            mapper.writeValue(gen, o);
        }
    } while (orderPage.hasNext());

    gen.writeEndArray();
}
```

### Python (orjson + JSONL)

```python
import orjson

with open("orders.jsonl", "wb") as f:
    page = 0
    while True:
        orders = order_repo.find_page(page, 10000)
        if not orders:
            break
        for o in orders:
            f.write(orjson.dumps(o.to_dict()))
            f.write(b"\n")
        page += 1
```

### Go (json.Encoder per-line)

```go
import (
    "encoding/json"
    "os"
)

func exportJSONL(orders []Order) error {
    f, err := os.Create("orders.jsonl")
    if err != nil {
        return err
    }
    defer f.Close()

    enc := json.NewEncoder(f)
    for _, o := range orders {
        if err := enc.Encode(o); err != nil {
            return err
        }
    }
    return nil
}
```

### Node.js (JSONStream)

```typescript
import JSONStream from 'JSONStream';
import { createWriteStream } from 'fs';

async function exportJSON(orders: AsyncIterable<Order>) {
    const output = createWriteStream('orders.json');
    const stringifier = JSONStream.stringify();
    stringifier.pipe(output);

    for await (const o of orders) {
        stringifier.write(o);
    }
    stringifier.end();
}
```

---

## PDF 流式写入

### Java (iText)

```java
try (PdfWriter writer = new PdfWriter("orders.pdf");
     PdfDocument pdf = new PdfDocument(writer);
     Document doc = new Document(pdf)) {

    int page = 0;
    int rowIdx = 0;
    Page<Order> orderPage;
    do {
        orderPage = orderRepo.findAll(PageRequest.of(page++, 1000));
        for (Order o : orderPage.getContent()) {
            doc.add(new Paragraph(o.getId() + " - " + o.getAmount()));
            rowIdx++;
            if (rowIdx % 100 == 0) {
                pdf.getWriter().flush();
            }
        }
    } while (orderPage.hasNext());
}
```

### Python (ReportLab)

```python
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4

c = canvas.Canvas("orders.pdf", pagesize=A4)
y = 800
page_num = 0

while True:
    orders = order_repo.find_page(page_num, 1000)
    if not orders:
        break
    for o in orders:
        if y < 50:
            c.showPage()
            y = 800
        c.drawString(50, y, f"{o.id} - {o.amount}")
        y -= 20
    page_num += 1

c.save()
```

### Go (gofpdf)

```go
import "github.com/jung-kurt/gofpdf"

func exportPDF(orders []Order) error {
    pdf := gofpdf.New("P", "mm", "A4", "")
    pdf.SetFont("Arial", "", 12)
    pdf.AddPage()

    for i, o := range orders {
        if i > 0 && i%40 == 0 {
            pdf.AddPage()
        }
        pdf.Cell(0, 10, fmt.Sprintf("%d - %s", o.ID, o.Amount.String()))
        pdf.Ln(10)
    }

    return pdf.OutputFileAndClose("orders.pdf")
}
```

**注意**：gofpdf 在 OutputFileAndClose 之前所有 page 都在内存。100w 行需要换 unidoc 或拆多文件。

### Node.js (PDFKit)

```typescript
import PDFDocument from 'pdfkit';
import { createWriteStream } from 'fs';

async function exportPDF(orders: AsyncIterable<Order>) {
    const doc = new PDFDocument();
    doc.pipe(createWriteStream('orders.pdf'));

    let count = 0;
    for await (const o of orders) {
        if (count > 0 && count % 40 === 0) {
            doc.addPage();
        }
        doc.text(`${o.id} - ${o.amount}`);
        count++;
    }
    doc.end();
}
```

---

## 异步任务化（导出 > 30s 必须）

### Java (Spring + @Async)

```java
@Service
@RequiredArgsConstructor
public class ExportService {
    private final ExportTaskRepository taskRepo;
    private final ExportWorker exportWorker;

    public String submit(ExportRequest req) {
        ExportTask task = ExportTask.builder()
            .id(UUID.randomUUID().toString())
            .status(ExportStatus.PROCESSING)
            .createdAt(LocalDateTime.now())
            .build();
        taskRepo.save(task);
        exportWorker.execute(task.getId(), req);
        return task.getId();
    }
}

@Service
@RequiredArgsConstructor
public class ExportWorker {
    private final ExportTaskRepository taskRepo;
    private final OssClient ossClient;

    @Async("exportExecutor")
    public void execute(String taskId, ExportRequest req) {
        File temp = null;
        try {
            temp = File.createTempFile("export-", ".xlsx");
            streamWriteExcel(temp, req);
            String url = ossClient.upload(temp);
            taskRepo.complete(taskId, url);
        } catch (Exception e) {
            taskRepo.fail(taskId, e.getMessage());
        } finally {
            if (temp != null) {
                temp.delete();
            }
        }
    }
}
```

### Python (Celery)

```python
@celery.task
def export_orders_task(task_id: str, query: dict):
    temp_path = None
    try:
        temp_path = f"/tmp/export-{task_id}.xlsx"
        stream_write_excel(temp_path, query)
        url = oss_client.upload(temp_path)
        task_repo.complete(task_id, url)
    except Exception as e:
        task_repo.fail(task_id, str(e))
    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)
```

### Go (worker pool)

```go
type ExportJob struct {
    TaskID string
    Query  Query
}

func startExportWorker(jobs <-chan ExportJob) {
    for job := range jobs {
        if err := handleExportJob(job); err != nil {
            taskRepo.Fail(job.TaskID, err.Error())
            continue
        }
    }
}

func handleExportJob(job ExportJob) error {
    tmpPath := filepath.Join(os.TempDir(), fmt.Sprintf("export-%s.xlsx", job.TaskID))
    defer os.Remove(tmpPath)

    if err := streamWriteExcel(tmpPath, job.Query); err != nil {
        return err
    }
    url, err := ossClient.Upload(tmpPath)
    if err != nil {
        return err
    }
    taskRepo.Complete(job.TaskID, url)
    return nil
}
```

---

> 异步任务的完整状态机、超时、幂等设计见 `cc-async-task-pattern` skill
