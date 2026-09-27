export class DatatableHelpers {

    static getActionButtonClass(action: any): string {
        const baseClasses = 'px-3 py-1.5 text-sm rounded-md transition-colors focus:outline-none focus:ring-2 focus:ring-offset-1';

        const colorClasses: Record<string, string> = {
            primary: 'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500',
            danger: 'bg-red-600 text-white hover:bg-red-700 focus:ring-red-500',
            warning: 'bg-yellow-600 text-white hover:bg-yellow-700 focus:ring-yellow-500',
            success: 'bg-green-600 text-white hover:bg-green-700 focus:ring-green-500',
            info: 'bg-blue-400 text-white hover:bg-blue-500 focus:ring-blue-400',
            secondary: 'bg-gray-600 text-white hover:bg-gray-700 focus:ring-gray-500'
        };

        // Ensure the color is one of the keys, fallback to 'primary'
        const colorKey = (action.color as keyof typeof colorClasses) || 'primary';
        return `${baseClasses} ${colorClasses[colorKey]}`;
    }


    static getPageButtonClass(currentPage: number): string {
        const isActive = false; // You would compare with actual current page
        return isActive
            ? 'bg-blue-600 text-white border-blue-600'
            : 'bg-white text-gray-700 hover:bg-gray-50';
    }

    static getPageNumbers(totalPages: number, currentPage: number, maxVisible: number = 5): number[] {
        const pages: number[] = [];
        const half = Math.floor(maxVisible / 2);

        let start = Math.max(1, currentPage - half);
        let end = Math.min(totalPages, start + maxVisible - 1);

        if (end - start + 1 < maxVisible) {
            start = Math.max(1, end - maxVisible + 1);
        }

        for (let i = start; i <= end; i++) {
            pages.push(i);
        }

        return pages;
    }

    static getColumnLabel(key: string, columns: any[]): string {
        const column = columns.find(col => col.key === key);
        return column ? column.label : key;
    }

    static exportToCSV(data: any[], columns: any[], filename: string = 'export.csv') {
        // Implementation for CSV export
    }

    static exportToExcel(data: any[], columns: any[], filename: string = 'export.xlsx') {
        // Implementation for Excel export
    }

    static exportToPDF(data: any[], columns: any[], filename: string = 'export.pdf') {
        // Implementation for PDF export
    }

    static validateRow(row: any, columns: any[]): { isValid: boolean; errors: string[] } {
        const errors: string[] = [];

        columns.forEach(column => {
            if (column.required && (row[column.key] === undefined || row[column.key] === null || row[column.key] === '')) {
                errors.push(`${column.label} is required`);
            }

            if (column.validation) {
                const error = column.validation(row[column.key]);
                if (error) errors.push(error);
            }
        });

        return {
            isValid: errors.length === 0,
            errors
        };
    }
}