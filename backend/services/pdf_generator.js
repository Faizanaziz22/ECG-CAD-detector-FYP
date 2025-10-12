const { PDFDocument, rgb, StandardFonts } = require('pdf-lib');
const fs = require('fs').promises;
const path = require('path');

class PDFGenerator {
  constructor() {
    this.reportsDir = path.join(__dirname, '../reports');
    this.ensureReportsDirectory();
  }

  async ensureReportsDirectory() {
    try {
      await fs.access(this.reportsDir);
    } catch (error) {
      await fs.mkdir(this.reportsDir, { recursive: true });
    }
  }

  async generateECGReport(ecgRecord) {
    try {
      // Create a new PDF document
      const pdfDoc = await PDFDocument.create();
      
      // Embed fonts
      const helveticaFont = await pdfDoc.embedFont(StandardFonts.Helvetica);
      const helveticaBoldFont = await pdfDoc.embedFont(StandardFonts.HelveticaBold);
      
      // Add a page
      const page = pdfDoc.addPage([595.28, 841.89]); // A4 size
      const { width, height } = page.getSize();
      
      // Define colors
      const primaryColor = rgb(0.18, 0.49, 0.20); // #2E7D32
      const textColor = rgb(0.2, 0.2, 0.2);
      const lightGray = rgb(0.9, 0.9, 0.9);
      const redColor = rgb(0.8, 0.2, 0.2);
      const greenColor = rgb(0.2, 0.6, 0.2);
      const orangeColor = rgb(0.8, 0.5, 0.2);
      
      let yPosition = height - 60;
      
      // Header
      page.drawText('ECG ANALYSIS REPORT', {
        x: 50,
        y: yPosition,
        size: 24,
        font: helveticaBoldFont,
        color: primaryColor,
      });
      
      yPosition -= 40;
      
      // Report info
      page.drawText(`Report ID: ${ecgRecord.id}`, {
        x: 50,
        y: yPosition,
        size: 12,
        font: helveticaFont,
        color: textColor,
      });
      
      page.drawText(`Generated: ${new Date().toLocaleDateString()}`, {
        x: 400,
        y: yPosition,
        size: 12,
        font: helveticaFont,
        color: textColor,
      });
      
      yPosition -= 40;
      
      // Patient Information Section
      this.drawSectionHeader(page, 'PATIENT INFORMATION', yPosition, helveticaBoldFont, primaryColor);
      yPosition -= 30;
      
      // Draw background for patient info
      page.drawRectangle({
        x: 50,
        y: yPosition - 60,
        width: width - 100,
        height: 80,
        color: lightGray,
      });
      
      page.drawText(`File Name: ${ecgRecord.fileName}`, {
        x: 70,
        y: yPosition - 20,
        size: 12,
        font: helveticaFont,
        color: textColor,
      });
      
      page.drawText(`Recording Type: ${ecgRecord.recordingType}`, {
        x: 70,
        y: yPosition - 40,
        size: 12,
        font: helveticaFont,
        color: textColor,
      });
      
      page.drawText(`Upload Date: ${new Date(ecgRecord.uploadDate).toLocaleDateString()}`, {
        x: 300,
        y: yPosition - 20,
        size: 12,
        font: helveticaFont,
        color: textColor,
      });
      
      if (ecgRecord.notes) {
        page.drawText(`Notes: ${ecgRecord.notes}`, {
          x: 300,
          y: yPosition - 40,
          size: 12,
          font: helveticaFont,
          color: textColor,
        });
      }
      
      yPosition -= 100;
      
      // AI Analysis Section
      this.drawSectionHeader(page, 'AI ANALYSIS RESULTS', yPosition, helveticaBoldFont, primaryColor);
      yPosition -= 30;
      
      // Classification result with colored background
      const classificationColor = this.getClassificationColor(ecgRecord.aiAnalysis.classification);
      
      page.drawRectangle({
        x: 50,
        y: yPosition - 80,
        width: width - 100,
        height: 100,
        color: classificationColor.withOpacity ? classificationColor : rgb(classificationColor.r * 0.1, classificationColor.g * 0.1, classificationColor.b * 0.1),
      });
      
      page.drawText('CLASSIFICATION:', {
        x: 70,
        y: yPosition - 20,
        size: 14,
        font: helveticaBoldFont,
        color: textColor,
      });
      
      page.drawText(ecgRecord.aiAnalysis.classification.toUpperCase(), {
        x: 200,
        y: yPosition - 20,
        size: 18,
        font: helveticaBoldFont,
        color: classificationColor,
      });
      
      page.drawText('CONFIDENCE SCORE:', {
        x: 70,
        y: yPosition - 45,
        size: 14,
        font: helveticaBoldFont,
        color: textColor,
      });
      
      page.drawText(`${ecgRecord.aiAnalysis.confidence}%`, {
        x: 220,
        y: yPosition - 45,
        size: 16,
        font: helveticaBoldFont,
        color: this.getConfidenceColor(ecgRecord.aiAnalysis.confidence),
      });
      
      page.drawText(`Analysis Date: ${new Date(ecgRecord.aiAnalysis.analysisDate).toLocaleDateString()}`, {
        x: 350,
        y: yPosition - 45,
        size: 12,
        font: helveticaFont,
        color: textColor,
      });
      
      yPosition -= 110;
      
      // AI Summary Section
      this.drawSectionHeader(page, 'AI SUMMARY', yPosition, helveticaBoldFont, primaryColor);
      yPosition -= 30;
      
      // Draw summary box
      page.drawRectangle({
        x: 50,
        y: yPosition - 80,
        width: width - 100,
        height: 100,
        color: rgb(0.95, 0.95, 1),
      });
      
      // Split summary into lines to fit in the box
      const summaryLines = this.wrapText(ecgRecord.aiAnalysis.summary, 70);
      let summaryY = yPosition - 20;
      
      summaryLines.forEach(line => {
        page.drawText(line, {
          x: 70,
          y: summaryY,
          size: 12,
          font: helveticaFont,
          color: textColor,
        });
        summaryY -= 15;
      });
      
      yPosition -= 110;
      
      // Doctor Review Section (if available)
      if (ecgRecord.doctorReview) {
        this.drawSectionHeader(page, 'DOCTOR REVIEW', yPosition, helveticaBoldFont, primaryColor);
        yPosition -= 30;
        
        page.drawRectangle({
          x: 50,
          y: yPosition - 120,
          width: width - 100,
          height: 140,
          color: rgb(0.95, 1, 0.95),
        });
        
        page.drawText(`Doctor: Dr. ${ecgRecord.doctorReview.doctorName}`, {
          x: 70,
          y: yPosition - 20,
          size: 12,
          font: helveticaBoldFont,
          color: textColor,
        });
        
        page.drawText(`Review Date: ${new Date(ecgRecord.doctorReview.reviewDate).toLocaleDateString()}`, {
          x: 300,
          y: yPosition - 20,
          size: 12,
          font: helveticaFont,
          color: textColor,
        });
        
        page.drawText('DIAGNOSIS:', {
          x: 70,
          y: yPosition - 45,
          size: 12,
          font: helveticaBoldFont,
          color: textColor,
        });
        
        const diagnosisLines = this.wrapText(ecgRecord.doctorReview.diagnosis, 60);
        let diagnosisY = yPosition - 60;
        
        diagnosisLines.forEach(line => {
          page.drawText(line, {
            x: 70,
            y: diagnosisY,
            size: 11,
            font: helveticaFont,
            color: textColor,
          });
          diagnosisY -= 14;
        });
        
        if (ecgRecord.doctorReview.recommendations) {
          page.drawText('RECOMMENDATIONS:', {
            x: 70,
            y: diagnosisY - 10,
            size: 12,
            font: helveticaBoldFont,
            color: textColor,
          });
          
          const recommendationLines = this.wrapText(ecgRecord.doctorReview.recommendations, 60);
          let recY = diagnosisY - 25;
          
          recommendationLines.forEach(line => {
            page.drawText(line, {
              x: 70,
              y: recY,
              size: 11,
              font: helveticaFont,
              color: textColor,
            });
            recY -= 14;
          });
        }
        
        yPosition -= 150;
      }
      
      // Footer
      page.drawText('This report is generated by AI analysis and should be reviewed by a medical professional.', {
        x: 50,
        y: 50,
        size: 10,
        font: helveticaFont,
        color: rgb(0.5, 0.5, 0.5),
      });
      
      page.drawText('Healthcare App - ECG Analysis System', {
        x: 400,
        y: 50,
        size: 10,
        font: helveticaFont,
        color: rgb(0.5, 0.5, 0.5),
      });
      
      // Save the PDF
      const pdfBytes = await pdfDoc.save();
      const fileName = `ecg_report_${ecgRecord.id}_${Date.now()}.pdf`;
      const filePath = path.join(this.reportsDir, fileName);
      
      await fs.writeFile(filePath, pdfBytes);
      
      return {
        fileName,
        filePath,
        size: pdfBytes.length
      };
      
    } catch (error) {
      console.error('Error generating PDF report:', error);
      throw new Error('Failed to generate PDF report');
    }
  }

  drawSectionHeader(page, title, y, font, color) {
    page.drawText(title, {
      x: 50,
      y: y,
      size: 16,
      font: font,
      color: color,
    });
    
    // Draw underline
    page.drawLine({
      start: { x: 50, y: y - 5 },
      end: { x: 250, y: y - 5 },
      thickness: 2,
      color: color,
    });
  }

  getClassificationColor(classification) {
    switch (classification.toLowerCase()) {
      case 'normal':
        return rgb(0.2, 0.6, 0.2); // Green
      case 'abnormal':
        return rgb(0.8, 0.2, 0.2); // Red
      case 'borderline':
        return rgb(0.8, 0.5, 0.2); // Orange
      default:
        return rgb(0.5, 0.5, 0.5); // Gray
    }
  }

  getConfidenceColor(confidence) {
    if (confidence >= 80) return rgb(0.2, 0.6, 0.2); // Green
    if (confidence >= 60) return rgb(0.8, 0.5, 0.2); // Orange
    return rgb(0.8, 0.2, 0.2); // Red
  }

  wrapText(text, maxCharsPerLine) {
    const words = text.split(' ');
    const lines = [];
    let currentLine = '';

    words.forEach(word => {
      if ((currentLine + word).length <= maxCharsPerLine) {
        currentLine += (currentLine ? ' ' : '') + word;
      } else {
        if (currentLine) {
          lines.push(currentLine);
        }
        currentLine = word;
      }
    });

    if (currentLine) {
      lines.push(currentLine);
    }

    return lines;
  }

  async getReportPath(fileName) {
    return path.join(this.reportsDir, fileName);
  }

  async deleteReport(fileName) {
    try {
      const filePath = path.join(this.reportsDir, fileName);
      await fs.unlink(filePath);
      return true;
    } catch (error) {
      console.error('Error deleting report:', error);
      return false;
    }
  }
}

module.exports = PDFGenerator;